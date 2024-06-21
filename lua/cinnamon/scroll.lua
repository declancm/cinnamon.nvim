local M = {}
local H = {}

local config = require("cinnamon.config")

M.scroll = function(command, options)
    if H.locked then
        return
    end
    H.locked = true

    options = vim.tbl_deep_extend("force", options or {}, {
        callback = nil,
        center = false,
        delay = 5,
        max_delta = {
            lnum = 100,
            col = 200,
        },
    })

    local original_position = H.get_position()
    local original_buffer = vim.api.nvim_get_current_buf()
    local original_window = vim.api.nvim_get_current_win()

    H.movement_setup()
    H.execute_movement(command)

    local final_buffer = vim.api.nvim_get_current_buf()
    local final_window = vim.api.nvim_get_current_win()
    local final_position = H.get_position()

    if
        original_buffer ~= final_buffer
        or original_window ~= final_window
        or H.positions_are_close(original_position, final_position)
        or vim.fn.foldclosed(final_position.lnum) ~= -1
        or math.abs(original_position.lnum - final_position.lnum) > options.max_delta.lnum
        or math.abs(original_position.col - final_position.col) > options.max_delta.col
    then
        H.cleanup(options)
        return
    end

    H.movement_teardown()
    H.scroll_setup()
    local target_position = H.calculate_target_position(final_position, options)
    H.vertical_scroller(target_position, options)
    H.horizontal_scroller(target_position, options)
end

H.execute_movement = function(command)
    if type(command) == "string" then
        if command[1] == ":" then
            -- Ex (command-line) command
            vim.cmd(vim.keycode(command:sub(2)))
        elseif command ~= "" then
            -- Normal mode command
            if vim.v.count ~= 0 then
                vim.cmd("normal! " .. vim.v.count .. vim.keycode(command))
            else
                vim.cmd("normal! " .. vim.keycode(command))
            end
        end
    elseif type(command) == "function" then
        local success, message = pcall(command)
        if not success then
            vim.notify(message)
        end
    end
end

H.horizontal_scroller = function(target_position, options)
    local initial_position = H.get_position()

    if initial_position.col < target_position.col then
        vim.cmd("normal! l")
        if H.get_position().wincol > target_position.wincol then
            vim.cmd("normal! zl")
        end
    elseif initial_position.col > target_position.col then
        vim.cmd("normal! h")
        if H.get_position().wincol < target_position.wincol then
            vim.cmd("normal! zh")
        end
    elseif initial_position.wincol < target_position.wincol then
        vim.cmd("normal! zh")
    elseif initial_position.wincol > target_position.wincol then
        vim.cmd("normal! zl")
    end

    H.horizontal_count = H.horizontal_count + 1

    local final_position = H.get_position()
    local scroll_complete = final_position.col == target_position.col
        and final_position.wincol == target_position.wincol
    local scroll_failed = (
        final_position.col == initial_position.col and final_position.wincol == initial_position.wincol
    ) or H.horizontal_count > options.max_delta.col + vim.api.nvim_win_get_width(0)

    if scroll_complete or scroll_failed then
        H.horizontal_scrolling = false
        H.cleanup(options)
        return
    end

    vim.defer_fn(function()
        H.horizontal_scroller(target_position, options)
    end, options.delay)
end

H.vertical_scroller = function(target_position, options)
    local initial_position = H.get_position()

    if initial_position.lnum < target_position.lnum then
        vim.cmd("normal! gj")
        if H.get_position().winline > target_position.winline then
            vim.cmd("normal! " .. vim.keycode("<c-e>"))
        end
    elseif initial_position.lnum > target_position.lnum then
        vim.cmd("normal! gk")
        if H.get_position().winline < target_position.winline then
            vim.cmd("normal! " .. vim.keycode("<c-y>"))
        end
    elseif initial_position.winline < target_position.winline then
        vim.cmd("normal! " .. vim.keycode("<c-y>"))
    elseif initial_position.winline > target_position.winline then
        vim.cmd("normal! " .. vim.keycode("<c-e>"))
    end

    H.vertical_count = H.vertical_count + 1

    local final_position = H.get_position()
    local scroll_complete = final_position.lnum == target_position.lnum
        and final_position.winline == target_position.winline
    local scroll_failed = (
        final_position.lnum == initial_position.lnum and final_position.winlHine == initial_position.winline
    ) or H.vertical_count > options.max_delta.lnum + vim.api.nvim_win_get_height(0)

    if scroll_complete or scroll_failed then
        H.vertical_scrolling = false
        H.cleanup(options)
        return
    end

    vim.defer_fn(function()
        H.vertical_scroller(target_position, options)
    end, options.delay)
end

H.cleanup = function(options)
    if H.vertical_scrolling or H.horizontal_scrolling then
        return
    end
    H.scroll_teardown()
    if options.callback ~= nil then
        local success, message = pcall(options.callback)
        if not success then
            vim.notify(message)
        end
    end
    H.locked = false
end

H.get_position = function()
    local curpos = vim.fn.getcurpos()
    return {
        lnum = curpos[2],
        col = curpos[3],
        off = curpos[4],
        curswant = curpos[5],
        winline = vim.fn.winline(),
        wincol = vim.fn.wincol(),
    }
end

H.positions_are_close = function(p1, p2)
    -- stylua: ignore start
    if math.abs(p1.lnum - p2.lnum) > 1 then return false end
    if math.abs(p1.winline - p2.winline) > 1 then return false end
    if math.abs(p1.col - p2.col) > 1 then return false end
    if math.abs(p1.wincol - p2.wincol) > 1 then return false end
    -- stylua: ignore end
    return true
end

H.movement_setup = function()
    H.original_view = vim.fn.winsaveview()
    H.vimopts:set("lazyredraw", "o", true)
end
H.movement_teardown = function()
    H.vimopts:restore("lazyredraw", "o")
end

H.scroll_setup = function()
    H.final_view = vim.fn.winsaveview()
    vim.fn.winrestview(H.original_view)
    H.horizontal_scrolling = true
    H.vertical_scrolling = true
    H.horizontal_count = 0
    H.vertical_count = 0
    H.vimopts:set("virtualedit", "o", "all")
end
H.scroll_teardown = function()
    -- Need to restore the final view in case something went wrong.
    -- It also restores the 'curswant' requires for movements with '$'.
    vim.fn.winrestview(H.final_view)
    H.vimopts:restore("virtualedit", "o")
end

H.vimopts = {}
function H.vimopts:set(option, context, value)
    self[option] = vim[context][option]
    vim[context][option] = value
end
function H.vimopts:restore(option, context)
    if vim[context][option] ~= self[option] then
        vim[context][option] = self[option]
    end
end

H.calculate_target_position = function(position, options)
    local target_position = position
    if options.center then
        target_position.winline = math.ceil(vim.api.nvim_win_get_height(0) / 2)
    end
    return target_position
end

return M
