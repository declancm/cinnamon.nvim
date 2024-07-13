local config = require("cinnamon.config")
local utils = require("cinnamon.utils")
local M = {}
local H = {}

---@class Position
---@field line number
---@field col number
---@field winline number
---@field wincol number

---@param command string | function
---@param options? ScrollOptions
M.scroll = function(command, options)
    H.scroller:init(command, options)
end

H.scroller = {
    ---@param command string | function
    ---@param options? ScrollOptions
    init = function(self, command, options)
        -- Lock the function to prevent re-entrancy. Must be first.
        if H.locked then
            return
        end
        H.locked = true

        self.options = vim.tbl_deep_extend("keep", options or {}, config.get().options)

        local original_view = vim.fn.winsaveview()
        local original_position = H.get_position()
        local original_buffer_id = vim.api.nvim_get_current_buf()
        local original_window_id = vim.api.nvim_get_current_win()

        vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonCmdPre" })
        H.execute_command(command)
        vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonCmdPost" })

        self.target_view = vim.fn.winsaveview()
        self.target_position = H.get_position()
        self.buffer_id = vim.api.nvim_get_current_buf()
        self.window_id = vim.api.nvim_get_current_win()

        local line_delta = H.get_line_delta(original_position, self.target_position)
        local column_delta = H.get_column_delta(original_position, self.target_position)
        self.vertical_step_size = self.options.step_size.vertical
        self.horizontal_step_size = self.options.step_size.horizontal
        self.step_delay = math.min(
            self.options.delay,
            (self.options.max_delta.time * self.vertical_step_size) / line_delta,
            (self.options.max_delta.time * self.horizontal_step_size) / column_delta
        )
        if self.step_delay < 1 then
            -- Skip steps so that there is always a smooth scroll
            self.vertical_step_size = math.ceil(self.vertical_step_size / self.step_delay)
            self.horizontal_step_size = math.ceil(self.horizontal_step_size / self.step_delay)
            self.step_delay = 1
        end
        self.step_delay = math.floor(self.step_delay)
        self.window_only = (self.options.mode ~= "cursor")

        local is_scrollable = (
            not config.disabled
            and not vim.g.cinnamon_disable
            and not vim.b.cinnamon_disable
            and vim.fn.reg_executing() == "" -- A macro is not being executed
            and original_buffer_id == self.buffer_id
            and original_window_id == self.window_id
            and vim.fn.foldclosed(self.target_position.line) == -1 -- Not within a closed fold
            and not H.positions_within_threshold(
                original_position,
                self.target_position,
                self.vertical_step_size,
                self.horizontal_step_size
            )
            and (not self.window_only or H.window_scrolled(original_view, self.target_view))
            and (not self.options.max_delta.line or (line_delta <= self.options.max_delta.line))
            and (not self.options.max_delta.column or (column_delta <= self.options.max_delta.column))
            and self.step_delay > 0
            and (math.max(self.vertical_step_size, self.horizontal_step_size) < math.huge)
        )

        if is_scrollable then
            vim.fn.winrestview(original_view)
            self:start()
        else
            self:cleanup()
        end
    end,

    start = function(self)
        if self.window_only then
            -- Hide the cursor
            vim.cmd("highlight Cursor blend=100")
            vim.opt.guicursor:append({ "a:Cursor/lCursor" })
        end

        self.saved_virtualedit = vim.wo.virtualedit
        vim.wo.virtualedit = "all" -- Allow the cursor to move anywhere
        self.saved_scrolloff = vim.wo.scrolloff
        vim.wo.scrolloff = 0 -- Don't scroll the view when the cursor is near the edge

        self.initial_changedtick = vim.b.changedtick
        self.previous_position = nil
        self.visited_positions = {}

        local timeout = self.options.max_delta.time + 1000
        self.timed_out = false
        self.timeout_timer = vim.uv.new_timer()
        self.timeout_timer:start(timeout, 0, function()
            self.timed_out = true
            utils.notify("Scroll timed out", "error", { schedule = true })
        end)

        vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonScrollPre" })

        self.scroll_scheduler = vim.uv.new_timer()
        local scroller_busy = false
        self.queued_steps = 0
        local previous_tick = vim.uv.hrtime() -- ns

        self.scroll_scheduler:start(0, self.step_delay, function()
            -- The timer isn't precise so the time between calls is measured
            local current_tick = vim.uv.hrtime() -- ns
            local elapsed = (current_tick - previous_tick) / 1e6 -- ms
            previous_tick = current_tick
            local steps = math.floor((elapsed / self.step_delay) + 0.5)
            self.queued_steps = self.queued_steps + steps

            -- Use a busy flag to prevent multiple calls to the scroll function
            if not scroller_busy then
                scroller_busy = true
                vim.schedule(function()
                    self:scroll()
                    scroller_busy = false
                end)
            end
        end)
    end,

    scroll = function(self)
        local saved_lazyredraw = vim.o.lazyredraw
        vim.o.lazyredraw = true

        while true do
            local position = H.get_position()
            local position_key = position.line
                .. ","
                .. position.col
                .. ","
                .. position.winline
                .. ","
                .. position.wincol
            local scroll_failed = (
                self.timed_out
                or (self.initial_changedtick ~= vim.b.changedtick)
                or (self.buffer_id ~= vim.api.nvim_get_current_buf())
                or (self.window_id ~= vim.api.nvim_get_current_win())
                or (self.previous_position ~= nil and H.positions_within_threshold(position, self.previous_position, 0, 0)) -- Deadlock
                or self.visited_positions[position_key] -- Loop
            )
            local scroll_complete = (
                not scroll_failed and H.positions_within_threshold(position, self.target_position, 0, 0)
            )
            self.visited_positions[position_key] = true
            self.previous_position = position

            if not scroll_complete and not scroll_failed then
                local topline = vim.fn.line("w0")
                self:move_step()
                local window_moved = (topline ~= vim.fn.line("w0"))
                local step_complete = not self.window_only or window_moved
                if step_complete then
                    self.queued_steps = self.queued_steps - 1
                    if self.queued_steps < 1 then
                        break
                    end
                end
            else
                self:stop()
                break
            end
        end

        vim.o.lazyredraw = saved_lazyredraw
    end,

    move_step = function(self)
        local moved_up = false
        local moved_down = false
        local moved_left = false
        local moved_right = false

        local horizontal_error
        if vim.wo.wrap then
            horizontal_error = self.target_position.wincol - vim.fn.wincol()
        else
            horizontal_error = self.target_position.col - vim.fn.virtcol(".")
        end
        if horizontal_error < 0 then
            H.move_cursor("left", -horizontal_error, self.horizontal_step_size)
            moved_left = true
        elseif horizontal_error > 0 then
            H.move_cursor("right", horizontal_error, self.horizontal_step_size)
            moved_right = true
        end

        local vertical_error = self.target_position.line - vim.fn.line(".")
        if vertical_error == 0 then
            if horizontal_error == 0 and self:line_is_wrapped() then
                -- If the column is not correct but the window column
                -- is, the cursor is on the wrong visual line.
                local col_diff = self.target_position.col - vim.fn.virtcol(".")
                if col_diff < 0 then
                    vertical_error = -1
                elseif col_diff > 0 then
                    vertical_error = 1
                end
            end
        end
        if vertical_error < 0 then
            H.move_cursor("up", -vertical_error, self.vertical_step_size)
            moved_up = true
        elseif vertical_error > 0 then
            H.move_cursor("down", vertical_error, self.vertical_step_size)
            moved_down = true
        end

        -- Don't scroll the view in the opposite direction of a cursor movement
        -- as the cursor will move twice.
        local winline_error = self.target_position.winline - vim.fn.winline()
        if winline_error ~= 0 then
            -- Only scroll when not on a wrapped section of a line because
            -- vertical scroll movements move by entire lines.
            if self:line_is_wrapped() then
                winline_error = 0
            end
        end
        if not moved_down and winline_error > 0 then
            H.scroll_view("up", winline_error, self.vertical_step_size)
        elseif not moved_up and winline_error < 0 then
            H.scroll_view("down", -winline_error, self.vertical_step_size)
        end

        -- When text is wrapped, the view can't be horizontally scrolled
        if not vim.wo.wrap then
            local wincol_error = self.target_position.wincol - vim.fn.wincol()
            if not moved_right and wincol_error > 0 then
                H.scroll_view("left", wincol_error, self.horizontal_step_size)
            elseif not moved_left and wincol_error < 0 then
                H.scroll_view("right", -wincol_error, self.horizontal_step_size)
            end
        end
    end,

    ---@return boolean
    line_is_wrapped = function(self)
        if vim.wo.wrap then
            local textoff = vim.fn.getwininfo(self.window_id)[1].textoff
            return vim.fn.virtcol(".") ~= vim.fn.wincol() - textoff
        end
        return false
    end,

    stop = function(self)
        self.scroll_scheduler:close()
        self.timeout_timer:close()

        if self.window_only then
            -- Restore the cursor
            vim.cmd("highlight Cursor blend=0")
            vim.opt.guicursor:remove({ "a:Cursor/lCursor" })
        end

        vim.wo[self.window_id].scrolloff = self.saved_scrolloff
        vim.wo[self.window_id].virtualedit = self.saved_virtualedit

        -- The 'curswant' value has to be set with cursor() for the '$' movement.
        -- Setting it with winrestview() causes issues when within 'scrolloff'.
        vim.api.nvim_win_call(self.window_id, function()
            vim.fn.cursor({
                self.target_view.lnum,
                self.target_view.col + 1,
                self.target_view.coladd,
                self.target_view.curswant + 1,
            })
            vim.cmd("redraw") -- Cursor isn't redrawn if the window was exited
        end)

        vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonScrollPost" })
        self:cleanup()
    end,

    cleanup = function(self)
        if self.options.callback ~= nil then
            local success, message = pcall(self.options.callback)
            if not success then
                utils.notify("Error executing callback: " .. message, "warn")
            end
        end
        H.locked = false
    end,
}

---@param command string | function
H.execute_command = function(command)
    if type(command) == "string" then
        if command[1] == ":" then
            -- Ex (command-line) command
            vim.cmd(utils.keycode(command:sub(2)))
        elseif command ~= "" then
            -- Normal mode command
            command = utils.keycode(command)
            if vim.v.count ~= 0 then
                command = vim.v.count .. command
            end
            -- Indexing the vim.cmd table gives a simpler error message
            local success, message = pcall(vim.cmd.normal, { command, bang = true })
            if not success then
                vim.notify(message:gsub("^Vim:", ""), vim.log.levels.ERROR)
            end
        end
    elseif type(command) == "function" then
        -- Lua function
        local success, message = pcall(command)
        if not success then
            utils.notify("Error executing command: " .. message, "warn")
        end
    end

    -- Some plugins rely on this event to modify the final cursor position
    vim.api.nvim_exec_autocmds("CursorMoved", {})
end

---@param direction "up" | "down" | "left" | "right"
---@param cursor_error number
---@param step_size number
H.move_cursor = function(direction, cursor_error, step_size)
    local command = "normal! "
    if step_size > cursor_error then
        step_size = cursor_error
    end
    if step_size > 1 then
        command = command .. step_size
    end
    if direction == "up" then
        command = command .. "gk"
    elseif direction == "down" then
        command = command .. "gj"
    elseif direction == "left" then
        command = command .. "h"
    elseif direction == "right" then
        command = command .. "l"
    else
        error("Invalid direction: " .. direction)
    end
    vim.cmd(command)
end

---@param direction "up" | "down" | "left" | "right"
---@param view_error number
---@param step_size number
H.scroll_view = function(direction, view_error, step_size)
    local command = "normal! "
    if step_size > view_error then
        step_size = view_error
    end
    if step_size > 1 then
        command = command .. step_size
    end
    if direction == "up" then
        command = command .. utils.keycode("<c-y>")
    elseif direction == "down" then
        command = command .. utils.keycode("<c-e>")
    elseif direction == "left" then
        command = command .. "zh"
    elseif direction == "right" then
        command = command .. "zl"
    else
        error("Invalid direction: " .. direction)
    end
    vim.cmd(command)
end

---@return Position
H.get_position = function()
    return {
        line = vim.fn.line("."),
        col = vim.fn.virtcol("."),
        winline = vim.fn.winline(),
        wincol = vim.fn.wincol(),
    }
end

---@param pos1 Position
---@param pos2 Position
---@return number
H.get_line_delta = function(pos1, pos2)
    -- TODO: handle wrapped lines
    local distance = 0
    local line1 = pos1.line
    local line2 = pos2.line
    local max_distance = math.abs(line2 - line1)
    local direction = (line2 > line1) and 1 or -1
    local get_fold_end = (direction == 1) and vim.fn.foldclosedend or vim.fn.foldclosed
    local line2_fold_end = get_fold_end(line2)

    local line = line1
    while line ~= line2 and distance < max_distance do
        local fold_end = get_fold_end(line)
        if fold_end ~= -1 then
            if (line2_fold_end ~= -1) and (fold_end == line2_fold_end) then
                -- The end line is within the same fold so the delta is the same
                return distance
            else
                -- Skip over the fold
                line = fold_end
            end
        end
        distance = distance + 1
        line = line + direction
    end

    return distance
end

---@param pos1 Position
---@param pos2 Position
---@return number
H.get_column_delta = function(pos1, pos2)
    if vim.wo.wrap then
        return math.abs(pos2.wincol - pos1.wincol)
    end
    return math.abs(pos2.col - pos1.col)
end

---@param pos1 Position
---@param pos2 Position
---@param horizontal_threshold number
---@param vertical_threshold number
H.positions_within_threshold = function(pos1, pos2, horizontal_threshold, vertical_threshold)
    -- stylua: ignore start
    if math.abs(pos1.line - pos2.line) > horizontal_threshold then return false end
    if math.abs(pos1.col - pos2.col) > vertical_threshold then return false end
    if math.abs(pos1.winline - pos2.winline) > horizontal_threshold then return false end
    if math.abs(pos1.wincol - pos2.wincol) > vertical_threshold then return false end
    -- stylua: ignore end
    return true
end

---@param view1 table
---@param view2 table
---@return boolean
H.window_scrolled = function(view1, view2)
    return view1.topline ~= view2.topline or view1.leftcol ~= view2.leftcol
end

return M
