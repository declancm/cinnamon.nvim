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

    -- TODO: Factor in folds, wrapped lines, virtual text etc in delta calculations
    local line_delta = math.abs(final_position.line - original_position.line)
    local column_delta = math.abs(final_position.col - original_position.col)
    local step_delay =
        math.floor(math.min(options.delay, options.max_delta.time / line_delta, options.max_delta.time / column_delta))

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
    )

    if is_scrollable then
        vim.fn.winrestview(original_view)
    end

    vim.o.lazyredraw = saved_lazyredraw

    if is_scrollable then
        H.scroller:start(final_position, final_view, final_buffer, final_window, step_delay, options)
    else
        H.cleanup(options)
    end
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
function H.scroller:start(target_position, target_view, buffer_id, window_id, step_delay, options)
    self.target_position = target_position
    self.target_view = target_view
    self.buffer_id = buffer_id
    self.window_id = window_id
    self.options = options
    self.scroll_cursor = (options.mode == "cursor")
    self.step_delay = step_delay

    if not self.scroll_cursor then
        -- Hide the cursor
        vim.cmd("highlight Cursor blend=100")
        vim.opt.guicursor:append({ "a:Cursor/lCursor" })
    end

    self.saved_virtualedit = vim.wo.virtualedit
    vim.wo.virtualedit = "all" -- Allow the cursor to move anywhere
    self.saved_scrolloff = vim.wo.scrolloff
    vim.wo.scrolloff = 0 -- Don't scroll the view when the cursor is near the edge

    self.initial_changedtick = vim.b.changedtick

    local timeout = options.max_delta.time + 1000
    self.timed_out = false
    self.timeout_timer = vim.uv.new_timer()
    self.timeout_timer:start(timeout, 0, function()
        self.timed_out = true
        utils.notify("Scroll timed out", "error", { schedule = true })
    end)

    vim.api.nvim_exec_autocmds("User", { pattern = "CinnamonScrollPre" })

    self.busy = false
    self.queued_steps = 0
    self.scroll_scheduler = vim.uv.new_timer()
    self.scroll_scheduler:start(0, self.step_delay, function()
        self.queued_steps = self.queued_steps + 1
        if not self.busy then
            self.busy = true
            vim.schedule(function()
                H.scroller:scroll()
            end)
        end
    end)
end

function H.scroller:scroll()
    local saved_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    while true do
        local scroll_failed = (
            self.timed_out
            or (self.initial_changedtick ~= vim.b.changedtick)
            or (self.buffer_id ~= vim.api.nvim_get_current_buf())
            or (self.window_id ~= vim.api.nvim_get_current_win())
        )
        local position = H.get_position()
        local scroll_complete = (
            not scroll_failed and H.positions_within_threshold(position, self.target_position, 0, 0)
        )

        if not scroll_complete and not scroll_failed then
            local topline = vim.fn.line("w0")
            self:move_step()
            local window_moved = (topline ~= vim.fn.line("w0"))
            if self.scroll_cursor or window_moved then
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
    self.busy = false
end

function H.scroller:move_step()
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
    -- Move 2 columns per step when possible since the columns
    -- are around half the size of lines.
    if horizontal_error < 0 then
        H.move_cursor("left", (horizontal_error < -1) and 2 or 1)
        moved_left = true
    elseif horizontal_error > 0 then
        H.move_cursor("right", (horizontal_error > 1) and 2 or 1)
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
        H.move_cursor("up")
        moved_up = true
    elseif vertical_error > 0 then
        H.move_cursor("down")
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
        H.scroll_view("up")
    elseif not moved_up and winline_error < 0 then
        H.scroll_view("down")
    end

    -- When text is wrapped, the view can't be horizontally scrolled
    if not vim.wo.wrap then
        local wincol_error = self.target_position.wincol - vim.fn.wincol()
        -- Move 2 columns per step when possible since the columns
        -- are around half the size of lines.
        if not moved_right and wincol_error > 0 then
            H.scroll_view("left", (wincol_error > 1) and 2 or 1)
        elseif not moved_left and wincol_error < 0 then
            H.scroll_view("right", (wincol_error < -1) and 2 or 1)
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

    if not self.scroll_cursor then
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
