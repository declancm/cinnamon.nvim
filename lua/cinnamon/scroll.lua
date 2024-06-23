local M = {}
local H = {}
local cache = {}

local config = require("cinnamon.config")

M.scroll = function(command, options)
    -- Lock the function to prevent re-entrancy. Must be first.
    if H.locked then
        return
    end
    H.locked = true
    cache = {}
    options = vim.tbl_deep_extend("force", options or {}, config.options)

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
        not config.disabled
        and original_buffer == final_buffer
        and original_window == final_window
        and not H.positions_within_threshold(original_position, final_position, 1, 2)
        and vim.fn.foldclosed(final_position.line) == -1
        and math.abs(original_position.line - final_position.line) <= options.max_delta.line
        and math.abs(original_position.col - final_position.col) <= options.max_delta.column
    then
        H.with_lazyredraw(vim.fn.winrestview, original_view)
        H.scroller:start(final_position, final_view, options)
    else
        H.cleanup(options)
    end
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
    self.win_height = vim.api.nvim_win_get_height(0)
    self.win_width = vim.api.nvim_win_get_width(0)

    -- Virtual editing allows for clean diagonal scrolling
    H.vimopts:set("virtualedit", "wo", "all")

    H.scroller:scroll()
end

function H.scroller:scroll()
    self:move_step()

    self.counter = self.counter + 1

    local final_position = H.get_position()
    local scroll_complete = H.positions_within_threshold(final_position, self.target_position, 0, 0)
    local scroll_failed = (
        (self.counter > self.options.max_delta.line + self.win_height)
        or (self.counter > self.options.max_delta.column + self.win_width)
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
    if line_error == 0 then
        -- If wrap is enabled, the lines might not be on the same visual line
        line_error = self.target_position.lineoff - H.get_visual_position().lineoff
    end
    if line_error < 0 then
        H.move_cursor("up")
        moved_up = true
    elseif line_error > 0 then
        H.move_cursor("down")
        moved_down = true
    end

    -- Move 2 columns at a time since the columns are around half the size of the lines
    local col_error = self.target_position.col - H.get_visual_position().col
    if col_error < 0 then
        H.move_cursor("left", (col_error < -1) and 2 or 1)
        moved_left = true
    elseif col_error > 0 then
        H.move_cursor("right", (col_error > 1) and 2 or 1)
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
        H.scroll_view("left", (wincol_error > 1) and 2 or 1)
    elseif not moved_left and wincol_error < 0 then
        H.scroll_view("right", (wincol_error < -1) and 2 or 1)
    end
end

function H.scroller:cleanup()
    -- The 'curswant' value has to be set with cursor() for the '$' movement.
    -- Setting it with winrestview() causes issues when within 'scrolloff'.
    vim.fn.cursor({
        self.target_view.line,
        self.target_view.col,
        self.target_view.off,
        self.target_view.curswant,
    })
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
    local visual_position = H.get_visual_position()
    return {
        line = vim.fn.line("."),
        lineoff = visual_position.lineoff,
        col = visual_position.col,
        winline = vim.fn.winline(),
        wincol = vim.fn.wincol(),
    }
end

H.get_visual_position = function()
    local wrap_width = H.get_wrap_width()
    local col = vim.fn.virtcol(".")
    local lineoff = 0
    while vim.wo.wrap and col > wrap_width do
        col = col - wrap_width
        lineoff = lineoff + 1
    end
    return { col = col, lineoff = lineoff }
end

H.get_wrap_width = function()
    if cache.wrap_width == nil then
        local winid = vim.api.nvim_get_current_win()
        local textoff = vim.fn.getwininfo(winid)[1].textoff
        cache.wrap_width = vim.api.nvim_win_get_width(winid) - textoff
    end
    return cache.wrap_width
end

H.positions_within_threshold = function(p1, p2, horizontal_threshold, vertical_threshold)
    -- stylua: ignore start
    if math.abs(p1.line - p2.line) > horizontal_threshold then return false end
    if math.abs(p1.lineoff - p2.lineoff) > horizontal_threshold then return false end
    if math.abs(p1.col - p2.col) > vertical_threshold then return false end
    if math.abs(p1.winline - p2.winline) > horizontal_threshold then return false end
    if math.abs(p1.wincol - p2.wincol) > vertical_threshold then return false end
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
