local M = {}

local config = require("cinnamon.config")

local vertical_scrolling = false
local horizontal_scrolling = false
local lock = false
local callback
local saved_virtualedit

local get_win_position = function()
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

local positions_are_close = function(p1, p2)
    -- stylua: ignore start
    if math.abs(p1.lnum - p2.lnum) > 1 then return false end
    if math.abs(p1.winline - p2.winline) > 1 then return false end
    if math.abs(p1.col - p2.col) > 1 then return false end
    if math.abs(p1.wincol - p2.wincol) > 1 then return false end
    -- stylua: ignore end
    return true
end

M.scroll = function(command, options)
    options = vim.tbl_deep_extend("force", options or {}, {
        callback = nil,
        center = false,
        delay = 5,
    })

    if lock then
        return
    end
    lock = true

    callback = options.callback

    local original_position = get_win_position()
    local original_buffer = vim.api.nvim_get_current_buf()

    local saved_view = vim.fn.winsaveview()

    local saved_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

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
        command()
    end

    if original_buffer ~= vim.api.nvim_get_current_buf() then
        vim.o.lazyredraw = saved_lazyredraw
        lock = false
        return
    end

    local final_position = get_win_position()
    if not positions_are_close(original_position, final_position) then
        if options.center then
            final_position.winline = math.ceil(vim.api.nvim_win_get_height(0) / 2)
        end
        vim.fn.winrestview(saved_view)
        vim.o.lazyredraw = saved_lazyredraw
        saved_virtualedit = vim.o.virtualedit
        vim.o.virtualedit = "all" -- Use virtual columns for horizontal scrolling.
        M.vertical_scroller(final_position, options.delay)
        M.horizontal_scroller(final_position, options.delay)
    end
end

M.horizontal_scroller = function(target_position, delay)
    horizontal_scrolling = true

    local initial_position = get_win_position()

    -- local col_delta = target_position.col - initial_position.col
    -- local wincol_delta = target_position.wincol - initial_position.wincol

    -- if col_delta > 0 then
    if initial_position.col < target_position.col then
        vim.cmd("normal! l")
        if get_win_position().wincol > target_position.wincol then
            vim.cmd("normal! zl")
        end
    elseif initial_position.col > target_position.col then
        vim.cmd("normal! h")
        if get_win_position().wincol < target_position.wincol then
            vim.cmd("normal! zh")
        end
    elseif initial_position.wincol < target_position.wincol then
        vim.cmd("normal! zh")
    elseif initial_position.wincol > target_position.wincol then
        vim.cmd("normal! zl")
    end

    local final_position = get_win_position()
    local scroll_complete = final_position.col == target_position.col
        and final_position.wincol == target_position.wincol
    local scroll_failed = final_position.col == initial_position.col
        and final_position.wincol == initial_position.wincol
    if scroll_complete or scroll_failed then
        vim.o.virtualedit = saved_virtualedit
        vim.fn.cursor({
            final_position.lnum,
            target_position.col,
            target_position.off,
            target_position.curswant,
        })
        if not vertical_scrolling then
            if type(callback) == "function" then
                callback()
            end
            lock = false
        end
        horizontal_scrolling = false
        return
    end

    vim.defer_fn(function()
        M.horizontal_scroller(target_position, delay)
    end, delay)
end

M.vertical_scroller = function(target_position, delay)
    vertical_scrolling = true
    local initial_position = get_win_position()

    if initial_position.lnum < target_position.lnum then
        vim.cmd("normal! gj")
        if get_win_position().winline > target_position.winline then
            vim.cmd("normal! " .. vim.keycode("<c-e>"))
        end
    elseif initial_position.lnum > target_position.lnum then
        vim.cmd("normal! gk")
        if get_win_position().winline < target_position.winline then
            vim.cmd("normal! " .. vim.keycode("<c-y>"))
        end
    elseif initial_position.winline < target_position.winline then
        vim.cmd("normal! " .. vim.keycode("<c-y>"))
    elseif initial_position.winline > target_position.winline then
        vim.cmd("normal! " .. vim.keycode("<c-e>"))
    end

    local final_position = get_win_position()
    local scroll_complete = final_position.lnum == target_position.lnum
        and final_position.winline == target_position.winline
    local scroll_failed = final_position.lnum == initial_position.lnum
        and final_position.winline == initial_position.winline
    if scroll_complete or scroll_failed then
        vim.fn.cursor({
            target_position.lnum,
            final_position.col,
        })
        if not horizontal_scrolling then
            if type(callback) == "function" then
                callback()
            end
            lock = false
        end
        vertical_scrolling = false
        return
    end

    vim.defer_fn(function()
        M.vertical_scroller(target_position, delay)
    end, delay)
end

return M
