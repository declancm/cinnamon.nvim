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
    -- Lock the function to prevent re-entrancy. Must be first.
    if H.locked then
        return
    end
    H.locked = true

    options = vim.tbl_deep_extend("keep", options or {}, config.get().options)

    local saved_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    local original_view = vim.fn.winsaveview()
    local original_position = H.get_position()
    local original_buffer = vim.api.nvim_get_current_buf()
    local original_window = vim.api.nvim_get_current_win()

    vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonCmdPre" })
    H.execute_command(command)
    vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonCmdPost" })

    local final_view = vim.fn.winsaveview()
    local final_position = H.get_position()
    local final_buffer = vim.api.nvim_get_current_buf()
    local final_window = vim.api.nvim_get_current_win()

    local line_delta = H.get_line_delta(original_position.line, final_position.line)
    local column_delta = H.get_column_delta(original_position.col, final_position.col)
    local step_size = 1
    local step_delay =
        math.min(options.delay, options.max_delta.time / line_delta, options.max_delta.time / column_delta)
    if step_delay < 1 then
        -- Skip steps so that there is always a smooth scroll
        step_size = math.ceil(1 / step_delay)
        step_delay = 1
    end
    step_delay = math.floor(step_delay)

    local is_scrollable = (
        not config.disabled
        and vim.fn.reg_executing() == "" -- A macro is not being executed
        and original_buffer == final_buffer
        and original_window == final_window
        and vim.fn.foldclosed(final_position.line) == -1 -- Not within a closed fold
        and not H.positions_within_threshold(original_position, final_position, 1, 2)
        and (options.max_delta.line == nil or (line_delta <= options.max_delta.line))
        and (options.max_delta.column == nil or (column_delta <= options.max_delta.column))
        and step_delay > 0
        and step_size < math.huge
    )

    if is_scrollable then
        vim.fn.winrestview(original_view)
    end

    vim.o.lazyredraw = saved_lazyredraw

    if is_scrollable then
        H.scroller:start(final_position, final_view, final_buffer, final_window, step_delay, step_size, options)
    else
        H.cleanup(options)
    end
end

---@param line1 number
---@param line2 number
---@return number
H.get_line_delta = function(line1, line2)
    -- TODO: handle wrapped lines
    local distance = 0
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

---@param col1 number
---@param col2 number
---@return number
H.get_column_delta = function(col1, col2)
    -- TODO: handle wrapped lines
    return math.abs(col2 - col1)
end

---@param command string | function
H.execute_command = function(command)
    if type(command) == "string" then
        if command[1] == ":" then
            -- Ex (command-line) command
            vim.cmd(vim.keycode(command:sub(2)))
        elseif command ~= "" then
            -- Normal mode command
            if vim.v.count ~= 0 then
                vim.cmd("silent! normal! " .. vim.v.count .. vim.keycode(command))
            else
                vim.cmd("silent! normal! " .. vim.keycode(command))
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
---@param count? number
H.move_cursor = function(direction, count)
    local command = "normal! "
    if count then
        command = command .. count
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
---@param count? number
H.scroll_view = function(direction, count)
    local command = "normal! "
    if count then
        command = command .. count
    end
    if direction == "up" then
        command = command .. vim.keycode("<c-y>")
    elseif direction == "down" then
        command = command .. vim.keycode("<c-e>")
    elseif direction == "left" then
        command = command .. "zh"
    elseif direction == "right" then
        command = command .. "zl"
    else
        error("Invalid direction: " .. direction)
    end
    vim.cmd(command)
end

H.scroller = {}

---@param target_position Position
---@param target_view table
---@param buffer_id number
---@param window_id number
---@param step_delay number
---@param options ScrollOptions
function H.scroller:start(target_position, target_view, buffer_id, window_id, step_delay, step_size, options)
    self.target_position = target_position
    self.target_view = target_view
    self.buffer_id = buffer_id
    self.window_id = window_id
    self.options = options
    self.window_only = (options.mode ~= "cursor")
    self.step_delay = step_delay
    self.vertical_step_size = step_size
    self.horizontal_step_size = step_size * 2

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

    local timeout = options.max_delta.time + 1000
    self.timed_out = false
    self.timeout_timer = vim.uv.new_timer()
    self.timeout_timer:start(timeout, 0, function()
        self.timed_out = true
        utils.notify("Scroll timed out", "error", { schedule = true })
    end)

    vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonScrollPre" })

    self.scroll_scheduler = vim.uv.new_timer()
    self.queued_steps = 0
    local scroller_busy = false
    self.scroll_scheduler:start(0, self.step_delay, function()
        self.queued_steps = self.queued_steps + 1
        if not scroller_busy then
            scroller_busy = true
            vim.schedule(function()
                self:scroll()
                scroller_busy = false
            end)
        end
    end)
end

function H.scroller:scroll()
    local saved_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    while true do
        local current_position = H.get_position()
        local scroll_failed = (
            self.timed_out
            or (self.initial_changedtick ~= vim.b.changedtick)
            or (self.buffer_id ~= vim.api.nvim_get_current_buf())
            or (self.window_id ~= vim.api.nvim_get_current_win())
            or (
                self.previous_position ~= nil
                and H.positions_within_threshold(current_position, self.previous_position, 0, 0)
            ) -- Deadlock
        )
        local scroll_complete = (
            not scroll_failed and H.positions_within_threshold(current_position, self.target_position, 0, 0)
        )
        self.previous_position = current_position

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
end

function H.scroller:move_step()
    local moved_up = false
    local moved_down = false
    local moved_left = false
    local moved_right = false
    local step_size

    local horizontal_error
    if vim.wo.wrap then
        horizontal_error = self.target_position.wincol - vim.fn.wincol()
    else
        horizontal_error = self.target_position.col - vim.fn.virtcol(".")
    end
    if math.abs(horizontal_error) > self.horizontal_step_size then
        step_size = self.horizontal_step_size
    else
        step_size = math.abs(horizontal_error)
    end
    if horizontal_error < 0 then
        H.move_cursor("left", step_size)
        moved_left = true
    elseif horizontal_error > 0 then
        H.move_cursor("right", step_size)
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
    if math.abs(vertical_error) > self.vertical_step_size then
        step_size = self.vertical_step_size
    else
        step_size = math.abs(vertical_error)
    end
    if vertical_error < 0 then
        H.move_cursor("up", step_size)
        moved_up = true
    elseif vertical_error > 0 then
        H.move_cursor("down", step_size)
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
    if math.abs(winline_error) > self.vertical_step_size then
        step_size = self.vertical_step_size
    else
        step_size = math.abs(winline_error)
    end
    if not moved_down and winline_error > 0 then
        H.scroll_view("up", step_size)
    elseif not moved_up and winline_error < 0 then
        H.scroll_view("down", step_size)
    end

    -- When text is wrapped, the view can't be horizontally scrolled
    if not vim.wo.wrap then
        local wincol_error = self.target_position.wincol - vim.fn.wincol()
        if math.abs(wincol_error) > self.horizontal_step_size then
            step_size = self.horizontal_step_size
        else
            step_size = math.abs(wincol_error)
        end
        if not moved_right and wincol_error > 0 then
            H.scroll_view("left", step_size)
        elseif not moved_left and wincol_error < 0 then
            H.scroll_view("right", step_size)
        end
    end
end

---@return boolean
function H.scroller:line_is_wrapped()
    if vim.wo.wrap then
        local textoff = vim.fn.getwininfo(self.window_id)[1].textoff
        return vim.fn.virtcol(".") ~= vim.fn.wincol() - textoff
    end
    return false
end

function H.scroller:stop()
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
    H.cleanup(self.options)
end

---@param options ScrollOptions
H.cleanup = function(options)
    if options.callback ~= nil then
        local success, message = pcall(options.callback)
        if not success then
            utils.notify("Error executing callback: " .. message, "warn")
        end
    end
    H.locked = false
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

---@param p1 Position
---@param p2 Position
---@param horizontal_threshold number
---@param vertical_threshold number
H.positions_within_threshold = function(p1, p2, horizontal_threshold, vertical_threshold)
    -- stylua: ignore start
    if math.abs(p1.line - p2.line) > horizontal_threshold then return false end
    if math.abs(p1.col - p2.col) > vertical_threshold then return false end
    if math.abs(p1.winline - p2.winline) > horizontal_threshold then return false end
    if math.abs(p1.wincol - p2.wincol) > vertical_threshold then return false end
    -- stylua: ignore end
    return true
end

return M
