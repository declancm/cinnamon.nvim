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
            self.interrupted = true
            vim.schedule(function()
                self:init(command, options)
            end)
            return
        end
        self.locked = true

        self.options = vim.tbl_deep_extend("keep", options or {}, config.get().options)
        self.window_only = (self.options.mode ~= "cursor")
        self.step_delay = math.max(math.floor(self.options.delay), 1)

        local original_window_id = vim.api.nvim_get_current_win()
        local original_buffer_id = vim.api.nvim_get_current_buf()
        local original_view = vim.fn.winsaveview()
        self.original_position = H.get_position()

        H.execute_command(command)

        self.window_id = vim.api.nvim_get_current_win()
        self.buffer_id = vim.api.nvim_get_current_buf()
        self.target_view = vim.fn.winsaveview()
        self.target_position = H.get_position()

        self.error = {
            line = H.get_line_error(self.original_position, self.target_position),
            col = self.target_position.col - self.original_position.col,
            winline = self.target_position.winline - self.original_position.winline,
            wincol = self.target_position.wincol - self.original_position.wincol,
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

        self.step_rate = {
            line = 0,
            col = 0,
            winline = 0,
            wincol = 0,
        }

        if vertical_step_count ~= 0 then
            self.step_rate.line = self.error.line / vertical_step_count
            self.step_rate.winline = self.error.winline / vertical_step_count
        end

        if horizontal_step_count ~= 0 then
            self.step_rate.col = self.error.col / horizontal_step_count
            self.step_rate.wincol = self.error.wincol / horizontal_step_count
        end

        if
            not config.disabled
            and not vim.g.cinnamon_disable
            and not vim.b.cinnamon_disable
            and step_count > 1
            and vim.fn.reg_executing() == "" -- A macro is not being executed
            and original_buffer_id == self.buffer_id
            and original_window_id == self.window_id
            and (not self.window_only or H.window_scrolled(original_view, self.target_view))
            and (not self.options.max_delta.line or (math.abs(self.error.line) <= self.options.max_delta.line))
            and (not self.options.max_delta.column or (math.abs(self.error.col) <= self.options.max_delta.column))
        then
            vim.fn.winrestview(original_view)
            self:start()
        else
            self:execute_callback()
            self.locked = false
        end
    end,

    start = function(self)
        vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonScrollPre" })

        if self.window_only then
            -- Hide the cursor
            vim.cmd("highlight Cursor blend=100")
            vim.opt.guicursor:append({ "a:Cursor/lCursor" })
        end

        self.saved_virtualedit = vim.wo.virtualedit
        vim.wo.virtualedit = "all" -- Allow the cursor to move anywhere
        self.saved_scrolloff = vim.wo.scrolloff
        vim.wo.scrolloff = 0 -- Don't scroll the view when the cursor is near the edge

        self.current_position = self.original_position
        self.initial_changedtick = vim.b.changedtick
        self.interrupted = false
        self.previous_step_position = nil
        self.previous_step_tick = utils.uv.hrtime() -- ns
        self.step_queue = {
            line = 0,
            col = 0,
            winline = 0,
            wincol = 0,
        }

        local timeout = self.options.max_delta.time + 1000
        self.timed_out = false
        self.timeout_timer = utils.uv.new_timer()
        self.timeout_timer:start(timeout, 0, function()
            self.timed_out = true
            utils.notify("Scroll timed out", "error", { schedule = true })
        end)

        self.scroll_scheduler = utils.uv.new_timer()
        local scroller_busy = false
        self.scroll_scheduler:start(0, self.step_delay, function()
            -- Use a busy flag to prevent multiple scheduled calls
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
            or self.interrupted
            or (self.window_id ~= vim.api.nvim_get_current_win())
            or (self.buffer_id ~= vim.api.nvim_get_current_buf())
            or (self.initial_changedtick ~= vim.b.changedtick)
            or (
                self.previous_step_position ~= nil
                and not H.positions_equal(H.get_position(), self.previous_step_position)
            )
        then
            self:stop()
            self.locked = false
            return
        end

        local current_step_tick = utils.uv.hrtime() -- ns
        local elapsed = (current_step_tick - self.previous_step_tick) / 1e6 -- ms
        self.previous_step_tick = current_step_tick
        local step_size = elapsed / self.step_delay

        self.step_queue.line = H.smaller(self.step_queue.line + step_size * self.step_rate.line, self.error.line)
        self.step_queue.col = H.smaller(self.step_queue.col + step_size * self.step_rate.col, self.error.col)
        self.step_queue.winline =
            H.smaller(self.step_queue.winline + step_size * self.step_rate.winline, self.error.winline)
        self.step_queue.wincol =
            H.smaller(self.step_queue.wincol + step_size * self.step_rate.wincol, self.error.wincol)

        local winline_before = vim.fn.winline()
        local wincol_before = vim.fn.wincol()

        local line_step = self:move_cursor("line", self.step_queue.line)
        local col_step = self:move_cursor("col", self.step_queue.col)

        local winline_step = vim.fn.winline() - winline_before
        local wincol_step = vim.fn.wincol() - wincol_before

        self.step_queue.line = self.step_queue.line - line_step
        self.step_queue.col = self.step_queue.col - col_step
        self.error.line = self.error.line - line_step
        self.error.col = self.error.col - col_step

        self.step_queue.winline = self.step_queue.winline - winline_step
        self.step_queue.wincol = self.step_queue.wincol - wincol_step
        self.error.winline = self.error.winline - winline_step
        self.error.wincol = self.error.wincol - wincol_step

        if vim.wo[self.window_id].wrap then
            winline_before = vim.fn.winline()
            self:move_window("winline", self.step_queue.winline)
            winline_step = vim.fn.winline() - winline_before
        else
            winline_step = self:move_window("winline", self.step_queue.winline)
            wincol_step = self:move_window("wincol", self.step_queue.wincol)

            self.step_queue.wincol = self.step_queue.wincol - wincol_step
            self.error.wincol = self.error.wincol - wincol_step
        end

        self.step_queue.winline = self.step_queue.winline - winline_step
        self.error.winline = self.error.winline - winline_step

        self.previous_step_position = H.get_position()

        if
            math.abs(self.error.line) < 1
            and math.abs(self.error.col) < 1
            and math.abs(self.error.winline) < 1
            and math.abs(self.error.wincol) < 1
        then
            self:move_to_target()
            self:stop()
            self:execute_callback()
            self.locked = false
            return
        end
    end,

    ---@param component "line" | "col"
    ---@param distance number
    move_cursor = function(self, component, distance)
        if distance > 0 then
            distance = math.floor(distance)
        else
            distance = math.ceil(distance)
        end

        if distance == 0 then
            return 0
        end

        self.current_position[component] = self.current_position[component] + distance
        vim.api.nvim_win_set_cursor(0, { self.current_position.line, self.current_position.col })

        return distance
    end,

    ---@param component "winline" | "wincol"
    ---@param distance number
    ---@return number
    move_window = function(self, component, distance)
        if distance > 0 then
            distance = math.floor(distance)
        else
            distance = math.ceil(distance)
        end
        local count = math.abs(distance)

        if count == 0 then
            return 0
        end

        local command = "normal! "
        if count > 1 then
            command = command .. count
        end

        if component == "winline" then
            command = command .. (distance > 0 and "\25" or "\5")
        else
            command = command .. (distance > 0 and "zh" or "zl")
        end

        vim.cmd(command)

        return distance
    end,

    move_to_target = function(self)
        if self.target_view == nil then
            error("Target view has not been set")
        end

        vim.api.nvim_win_call(self.window_id, function()
            vim.fn.winrestview(self.target_view)
        end)

        vim.cmd.redraw()
    end,

    execute_callback = function(self)
        local callback = self.options.callback or self.options._weak_callback
        if callback ~= nil then
            local success, message = pcall(callback)
            if not success then
                utils.notify("Error executing callback: " .. message, "warn")
            end
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

        vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonScrollPost" })
    end,
}

---@param command string | function
H.execute_command = function(command)
    vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonCmdPre" })

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

    vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonCmdPost" })
end

---@return Position
H.get_position = function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    return {
        line = cursor[1],
        col = cursor[2],
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
    if math.abs(pos1.line    - pos2.line   ) > threshold then return false end
    if math.abs(pos1.col     - pos2.col    ) > threshold then return false end
    if math.abs(pos1.winline - pos2.winline) > threshold then return false end
    if math.abs(pos1.wincol  - pos2.wincol ) > threshold then return false end
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
