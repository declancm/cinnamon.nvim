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
        if self.locked then
            return
        end
        self.locked = true

        self.options = vim.tbl_deep_extend("keep", options or {}, config.get().options)
        self.window_only = (self.options.mode ~= "cursor")
        self.step_delay = math.max(math.floor(self.options.delay), 1)

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

        self.error = {
            line = H.get_line_error(original_position, self.target_position),
            col = self.target_position.col - original_position.col,
            winline = self.target_position.winline - original_position.winline,
            wincol = self.target_position.wincol - original_position.wincol,
        }

        local step_count = math.max(
            math.abs(self.error.line / self.options.step_size.vertical),
            math.abs(self.error.col / self.options.step_size.horizontal),
            math.abs(self.error.winline / self.options.step_size.vertical),
            math.abs(self.error.wincol / self.options.step_size.horizontal)
        )

        local duration = math.min(self.options.max_delta.time, self.step_delay * step_count)
        local vertical_step_count = duration / self.step_delay
        local horizontal_step_count = duration / self.step_delay

        self.rates = {
            line = self.error.line / vertical_step_count,
            col = self.error.col / horizontal_step_count,
            winline = self.error.winline / vertical_step_count,
            wincol = self.error.wincol / horizontal_step_count,
        }

        if
            not config.disabled
            and not vim.g.cinnamon_disable
            and not vim.b.cinnamon_disable
            and vim.fn.reg_executing() == "" -- A macro is not being executed
            and original_buffer_id == self.buffer_id
            and original_window_id == self.window_id
            and (not self.window_only or H.window_scrolled(original_view, self.target_view))
            and (self.prev_now == nil or (utils.uv.now() - self.prev_now) > 100) -- Not a held key
            and (not self.options.max_delta.line or (math.abs(self.error.line) <= self.options.max_delta.line))
            and (not self.options.max_delta.column or (math.abs(self.error.col) <= self.options.max_delta.column))
        then
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
        self.previous_position = nil -- Check if the cursor moved inbetween scroll steps

        local timeout = self.options.max_delta.time + 1000
        self.timed_out = false
        self.timeout_timer = utils.uv.new_timer()
        self.timeout_timer:start(timeout, 0, function()
            self.timed_out = true
            utils.notify("Scroll timed out", "error", { schedule = true })
        end)

        vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonScrollPre" })

        self.scroll_scheduler = utils.uv.new_timer()
        local scroller_busy = false
        local previous_tick = utils.uv.hrtime() -- ns
        self.queue = {
            line = 0,
            col = 0,
            winline = 0,
            wincol = 0,
        }

        self.scroll_scheduler:start(0, self.step_delay, function()
            -- The timer isn't precise so the time between calls is measured
            local current_tick = utils.uv.hrtime() -- ns
            local elapsed = (current_tick - previous_tick) / 1e6 -- ms
            previous_tick = current_tick
            local size = elapsed / self.step_delay

            self.queue.line = H.smaller(self.queue.line + size * self.rates.line, self.error.line)
            self.queue.col = H.smaller(self.queue.col + size * self.rates.col, self.error.col)
            self.queue.winline = H.smaller(self.queue.winline + size * self.rates.winline, self.error.winline)
            self.queue.wincol = H.smaller(self.queue.wincol + size * self.rates.wincol, self.error.wincol)

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
        if
            self.timed_out
            or (self.window_id ~= vim.api.nvim_get_current_win())
            or (self.buffer_id ~= vim.api.nvim_get_current_buf())
            or (self.initial_changedtick ~= vim.b.changedtick)
            or (self.previous_position ~= nil and not H.positions_equal(H.get_position(), self.previous_position))
        then
            self:stop()
            return
        end

        local winline_before = vim.fn.winline()
        local wincol_before = vim.fn.wincol()

        local line_step = H.move_step("line", self.queue.line)
        local col_step = H.move_step("col", self.queue.col)

        self.queue.line = self.queue.line - line_step
        self.error.line = self.error.line - line_step
        self.queue.col = self.queue.col - col_step
        self.error.col = self.error.col - col_step

        local winline_change = vim.fn.winline() - winline_before
        local wincol_change = vim.fn.wincol() - wincol_before

        self.queue.winline = self.queue.winline - winline_change
        self.error.winline = self.error.winline - winline_change
        self.queue.wincol = self.queue.wincol - wincol_change
        self.error.wincol = self.error.wincol - wincol_change

        local winline_step = H.move_step("winline", self.queue.winline)
        local wincol_step = H.move_step("wincol", self.queue.wincol)

        self.queue.winline = self.queue.winline - winline_step
        self.error.winline = self.error.winline - winline_step
        self.queue.wincol = self.queue.wincol - wincol_step
        self.error.wincol = self.error.wincol - wincol_step

        self.previous_position = H.get_position()

        if
            math.abs(self.error.line) < 1
            and math.abs(self.error.col) < 1
            and math.abs(self.error.winline) < 1
            and math.abs(self.error.wincol) < 1
        then
            self:stop()
            return
        end
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
        local callback = self.options.callback or self.options._weak_callback
        if callback ~= nil then
            local success, message = pcall(callback)
            if not success then
                utils.notify("Error executing callback: " .. message, "warn")
            end
        end
        self.prev_now = utils.uv.now()
        self.locked = false
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

---@param component "line" | "col" | "winline" | "wincol"
---@param distance number
---@return number
H.move_step = function(component, distance)
    local command = "normal! "
    local movement = ""
    local count = math.floor(math.abs(distance))

    if count == 0 then
        return 0
    elseif count > 1 then
        command = command .. count
    end

    if component == "line" then
        movement = distance > 0 and "j" or "k"
    elseif component == "col" then
        movement = distance > 0 and "l" or "h"
    elseif component == "winline" then
        movement = distance > 0 and "\25" or "\5"
    elseif component == "wincol" then
        movement = distance > 0 and "zh" or "zl"
    else
        error("Invalid component: " .. component)
    end

    vim.cmd(command .. movement)

    return (distance < 0) and -count or count
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

---@param pos1 Position | {line: number}
---@param pos2 Position | {line: number}
---@return number
H.get_line_error = function(pos1, pos2)
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
                -- The end line is within the same fold so the distance is the same
                return distance
            else
                -- Skip over the fold
                line = fold_end
            end
        end
        distance = distance + direction
        line = line + direction
    end

    return distance
end

---@param pos1 Position
---@param pos2 Position
---@param threshold? number
H.positions_equal = function(pos1, pos2, threshold)
    threshold = threshold or 0
    -- stylua: ignore start
    if math.abs(pos1.line - pos2.line) > threshold then return false end
    if math.abs(pos1.col - pos2.col) > threshold then return false end
    if math.abs(pos1.winline - pos2.winline) > threshold then return false end
    if math.abs(pos1.wincol - pos2.wincol) > threshold then return false end
    -- stylua: ignore end
    return true
end

---@param view1 table
---@param view2 table
---@return boolean
H.window_scrolled = function(view1, view2)
    return view1.topline ~= view2.topline or view1.leftcol ~= view2.leftcol
end

---@param a number
---@param b number
---@return number
H.smaller = function(a, b)
    return (math.abs(a) < math.abs(b)) and a or b
end

return M
