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
            lnum = 150,
            col = 200,
        },
    })

    H.original_view = vim.fn.winsaveview()
    local original_position = H.get_position()
    local original_buffer = vim.api.nvim_get_current_buf()
    local original_window = vim.api.nvim_get_current_win()

    H.with_lazyredraw(H.execute_movement, command)

    H.final_view = vim.fn.winsaveview()
    local final_position = H.get_position()
    local final_buffer = vim.api.nvim_get_current_buf()
    local final_window = vim.api.nvim_get_current_win()

    if
        original_buffer ~= final_buffer
        or original_window ~= final_window
        or H.positions_are_close(original_position, final_position)
        or vim.fn.foldclosed(final_position.lnum) ~= -1
        or math.abs(original_position.lnum - final_position.lnum) > options.max_delta.lnum
        or math.abs(original_position.virtcol - final_position.virtcol) > options.max_delta.col
    then
        H.cleanup(options)
        return
    end

    H.scrollers_setup()
    H.vertical_scroller(final_position, options)
    H.horizontal_scroller(final_position, options)
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
    local command = "normal! " .. (count or 1)
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
    local command = "normal! " .. (count or 1)
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

H.horizontal_scroller = function(target_position, options)
    local initial_position = H.get_position()
    local moved_right = false
    local moved_left = false

    -- Move 2 columns at a time since the columns are around half the size of the lines
    local virtcol_error = target_position.virtcol - initial_position.virtcol
    if virtcol_error > 1 then
        H.move_cursor("right", 2)
        moved_right = true
    elseif virtcol_error < -1 then
        H.move_cursor("left", 2)
        moved_left = true
    end

    local wincol_error = target_position.wincol - H.get_position().wincol
    if not moved_right and wincol_error > 1 then
        H.scroll_view("right", 2)
    elseif not moved_left and wincol_error < -1 then
        H.scroll_view("left", 2)
    end

    H.horizontal_count = H.horizontal_count + 2

    local final_position = H.get_position()
    local scroll_complete = final_position.virtcol == target_position.virtcol
        and final_position.wincol == target_position.wincol
    local scroll_failed = H.horizontal_count > options.max_delta.col + vim.api.nvim_win_get_width(0)

    if scroll_complete or scroll_failed then
        H.horizontal_scrolling = false
        if not H.vertical_scrolling then
            H.scrollers_teardown()
            H.cleanup(options)
        end
        return
    end

    vim.defer_fn(function()
        H.horizontal_scroller(target_position, options)
    end, options.delay)
end

H.vertical_scroller = function(target_position, options)
    local initial_position = H.get_position()
    local moved_up = false
    local moved_down = false

    local lnum_error = target_position.lnum - initial_position.lnum
    if lnum_error < 0 then
        H.move_cursor("up")
        moved_up = true
    elseif lnum_error > 0 then
        H.move_cursor("down")
        moved_down = true
    end

    local winline_error = target_position.winline - H.get_position().winline
    if not moved_down and winline_error > 0 then
        H.scroll_view("up")
    elseif not moved_up and winline_error < 0 then
        H.scroll_view("down")
    end

    H.vertical_count = H.vertical_count + 1

    local final_position = H.get_position()
    local scroll_complete = final_position.lnum == target_position.lnum
        and final_position.winline == target_position.winline
    local scroll_failed = H.vertical_count > options.max_delta.lnum + vim.api.nvim_win_get_height(0)

    if scroll_complete or scroll_failed then
        H.vertical_scrolling = false
        if not H.horizontal_scrolling then
            H.scrollers_teardown()
            H.cleanup(options)
        end
        return
    end

    vim.defer_fn(function()
        H.vertical_scroller(target_position, options)
    end, options.delay)
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
    local curpos = vim.fn.getcurpos()
    local view = vim.fn.winsaveview()
    return {
        lnum = curpos[2],
        col = curpos[3] + view.coladd, -- Account for 'virtualedit'
        virtcol = vim.fn.virtcol("."),
        winline = vim.fn.winline(),
        wincol = vim.fn.wincol(),
    }
end

H.positions_are_close = function(p1, p2)
    -- stylua: ignore start
    if math.abs(p1.lnum - p2.lnum) > 1 then return false end
    if math.abs(p1.winline - p2.winline) > 1 then return false end
    if math.abs(p1.virtcol - p2.virtcol) > 2 then return false end
    if math.abs(p1.wincol - p2.wincol) > 2 then return false end
    -- stylua: ignore end
    return true
end

H.scrollers_setup = function()
    H.with_lazyredraw(vim.fn.winrestview, H.original_view)

    H.horizontal_scrolling = true
    H.vertical_scrolling = true

    H.horizontal_count = 0
    H.vertical_count = 0

    -- Virtual editing allows for clean diagonal scrolling
    H.vimopts:set("virtualedit", "all", "wo")
end

H.scrollers_teardown = function()
    -- Need to restore the final view in case something went wrong.
    -- It also restores the 'curswant' requires for movements with '$'.
    vim.fn.winrestview(H.final_view)

    H.vimopts:restore("virtualedit", "wo")
end

H.vimopts = { _opts = {} }
function H.vimopts:set(option, value, context)
    assert(self._opts[option] == nil, "Vim option already saved")
    context = context or "o"
    self._opts[option] = vim[context][option]
    vim[context][option] = value
end
function H.vimopts:restore(option, context)
    assert(self._opts[option] ~= nil, "Vim option already restored")
    context = context or "o"
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
        H.vimopts:set("lazyredraw", true)
    end
    func(...)
    if H.vimopts:is_set("lazyredraw") then
        H.vimopts:restore("lazyredraw")
    end
end

return M
