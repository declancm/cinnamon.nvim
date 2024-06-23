local M = {}
local H = {}

local config = require("cinnamon.config")

M.scroll = function(command, options)
    -- Lock the function to prevent re-entrancy. Must be first.
    if H.locked then
        return
    end
    H.locked = true

    options = vim.tbl_deep_extend("force", options or {}, {
        callback = nil,
        center = false,
        delay = 5,
        max_delta = {
            line = 150,
            column = 200,
        },
    })

    local original_view = vim.fn.winsaveview()
    local original_position = H.get_position()
    local original_buffer = vim.api.nvim_get_current_buf()
    local original_window = vim.api.nvim_get_current_win()

    H.with_lazyredraw(H.execute_movement, command)

    local final_view = vim.fn.winsaveview()
    local final_position = H.get_position()
    local final_buffer = vim.api.nvim_get_current_buf()
    local final_window = vim.api.nvim_get_current_win()

    if
        original_buffer ~= final_buffer
        or original_window ~= final_window
        or H.positions_are_close(original_position, final_position)
        or vim.fn.foldclosed(final_position.line) ~= -1
        or math.abs(original_position.line - final_position.line) > options.max_delta.line
        or math.abs(original_position.col - final_position.col) > options.max_delta.column
    then
        H.cleanup(options)
        return
    end

    H.with_lazyredraw(vim.fn.winrestview, original_view)
    H.scroller:start(final_position, final_view, options)
end

H.execute_movement = function(command)
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
            vim.notify(message)
        end
    end
end

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

function H.scroller:start(target_position, target_view, options)
    self.target_position = target_position
    self.target_view = target_view
    self.counter = 0
    self.options = options

    -- Virtual editing allows for clean diagonal scrolling
    H.vimopts:set("virtualedit", "wo", "all")

    H.scroller:scroll()
end

function H.scroller:scroll()
    self:move_step()

    self.counter = self.counter + 1

    local final_position = H.get_position()
    local scroll_complete = (
        final_position.line == self.target_position.line
        and final_position.col == self.target_position.col
        and final_position.winline == self.target_position.winline
        and final_position.wincol == self.target_position.wincol
    )
    local scroll_failed = (
        (self.counter > self.options.max_delta.line + vim.api.nvim_win_get_height(0))
        or (self.counter > self.options.max_delta.column + vim.api.nvim_win_get_width(0))
    )

    if not scroll_complete and not scroll_failed then
        vim.defer_fn(function()
            H.scroller:scroll()
        end, self.options.delay)
    else
        self:cleanup()
    end
end

function H.scroller:move_step()
    local moved_up = false
    local moved_down = false
    local moved_left = false
    local moved_right = false

    local line_error = self.target_position.line - vim.fn.line(".")
    if line_error < 0 then
        H.move_cursor("up")
        moved_up = true
    elseif line_error > 0 then
        H.move_cursor("down")
        moved_down = true
    end

    -- Move 2 columns at a time since the columns are around half the size of the lines
    local col_error = self.target_position.col - vim.fn.virtcol(".")
    if col_error < 0 then
        H.move_cursor("left", (col_error == -1) and 1 or 2)
        moved_left = true
    elseif col_error > 0 then
        H.move_cursor("right", (col_error == 1) and 1 or 2)
        moved_right = true
    end

    -- Don't scroll the view in the opposite direction of a cursor movement
    -- as the cursor will move twice.
    local winline_error = self.target_position.winline - vim.fn.winline()
    if not moved_down and winline_error > 0 then
        H.scroll_view("up")
    elseif not moved_up and winline_error < 0 then
        H.scroll_view("down")
    end

    local wincol_error = self.target_position.wincol - vim.fn.wincol()
    if not moved_right and wincol_error > 0 then
        H.scroll_view("left", (wincol_error == 1) and 1 or 2)
    elseif not moved_left and wincol_error < 0 then
        H.scroll_view("right", (wincol_error == -1) and 1 or 2)
    end
end

function H.scroller:cleanup()
    -- Need to restore the final view in case something went wrong.
    -- It also restores the 'curswant' required for movements with '$'.
    -- FIX: This causes the cursor to move out of 'scrolloff' at the bottom of the window
    vim.fn.winrestview(self.target_view)
    H.vimopts:restore("virtualedit", "wo")
    H.cleanup(self.options)
end

H.cleanup = function(options)
    if options.callback ~= nil then
        local success, message = pcall(options.callback)
        if not success then
            vim.notify(message)
        end
    end
    H.locked = false

    assert(not H.vimopts:are_set(), "Not all Vim options were restored")
end

H.get_position = function()
    return {
        line = vim.fn.line("."),
        col = vim.fn.virtcol("."),
        winline = vim.fn.winline(),
        wincol = vim.fn.wincol(),
    }
end

H.positions_are_close = function(p1, p2)
    -- stylua: ignore start
    if math.abs(p1.line - p2.line) > 1 then return false end
    if math.abs(p1.winline - p2.winline) > 1 then return false end
    if math.abs(p1.col - p2.col) > 2 then return false end
    if math.abs(p1.wincol - p2.wincol) > 2 then return false end
    -- stylua: ignore end
    return true
end

H.vimopts = { _opts = {} }
function H.vimopts:set(option, context, value)
    assert(self._opts[option] == nil, "Vim option '" .. option .. "' already saved")
    self._opts[option] = vim[context][option]
    vim[context][option] = value
end
function H.vimopts:restore(option, context)
    assert(self._opts[option] ~= nil, "Vim option '" .. option .. "' already restored")
    if vim[context][option] ~= self._opts[option] then
        vim[context][option] = self._opts[option]
    end
    self._opts[option] = nil
end
function H.vimopts:is_set(option)
    return self._opts[option] ~= nil
end
function H.vimopts:are_set()
    return next(self._opts) ~= nil
end

H.with_lazyredraw = function(func, ...)
    -- Need to check if already set and restored in case of nested calls
    if not H.vimopts:is_set("lazyredraw") then
        H.vimopts:set("lazyredraw", "o", true)
    end
    func(...)
    if H.vimopts:is_set("lazyredraw") then
        H.vimopts:restore("lazyredraw", "o")
    end
end

return M
