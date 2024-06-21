local M = {}
local H = {}

local config = require("cinnamon.config")

local vertical_scrolling = false
local horizontal_scrolling = false
local locked = false

M.scroll = function(command, options)
    if locked then
        return
    end
    locked = true

    options = vim.tbl_deep_extend("force", options or {}, {
        callback = nil,
        center = false,
        delay = 5,
    })

    local original_position = H.get_position()
    local original_buffer = vim.api.nvim_get_current_buf()
    local original_window = vim.api.nvim_get_current_win()
    local saved_view = vim.fn.winsaveview()

    H.movement_vimopts:set_all()

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

    local final_buffer = vim.api.nvim_get_current_buf()
    local final_window = vim.api.nvim_get_current_win()
    local final_position = H.get_position()

    if
        original_buffer ~= final_buffer
        or original_window ~= final_window
        or H.positions_are_close(original_position, final_position)
    then
        H.movement_vimopts:restore_all()
        locked = false
        return
    end

    vim.fn.winrestview(saved_view)
    H.movement_vimopts:restore_all()
    H.scroll_vimopts:set_all()
    H.callback = options.callback
    local target_position = H.get_target_position(final_position, options)
    H.vertical_scroller(target_position, options.delay)
    H.horizontal_scroller(target_position, options.delay)
end

H.horizontal_scroller = function(target_position, delay)
    horizontal_scrolling = true
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

    local final_position = H.get_position()
    local scroll_complete = final_position.col == target_position.col
        and final_position.wincol == target_position.wincol
    local scroll_failed = final_position.col == initial_position.col
        and final_position.wincol == initial_position.wincol
    if scroll_complete or scroll_failed then
        horizontal_scrolling = false
        vim.o.virtualedit = H.saved_virtualedit
        vim.fn.cursor({
            final_position.lnum,
            target_position.col,
            target_position.off,
            target_position.curswant,
        })
        if not vertical_scrolling then
            if type(H.callback) == "function" then
                H.callback()
            end
            locked = false
        end
        return
    end

    vim.defer_fn(function()
        H.horizontal_scroller(target_position, delay)
    end, delay)
end

H.vertical_scroller = function(target_position, delay)
    vertical_scrolling = true
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

    local final_position = H.get_position()
    local scroll_complete = final_position.lnum == target_position.lnum
        and final_position.winline == target_position.winline
    local scroll_failed = final_position.lnum == initial_position.lnum
        and final_position.winlHine == initial_position.winline
    if scroll_complete or scroll_failed then
        vertical_scrolling = false
        vim.fn.cursor({
            target_position.lnum,
            final_position.col,
        })
        if not horizontal_scrolling then
            if type(H.callback) == "function" then
                H.callback()
            end
            locked = false
        end
        return
    end

    vim.defer_fn(function()
        H.vertical_scroller(target_position, delay)
    end, delay)
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

local vimopts = {}
function vimopts:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function vimopts:set(option, context, value)
    vimopts[option] = vim[context][option]
    vim[context][option] = value
end
function vimopts:restore(option, context)
    if vim[context][option] ~= vimopts[option] then
        vim[context][option] = vimopts[option]
    end
end

H.movement_vimopts = vimopts:new()
function H.movement_vimopts:set_all()
    self:set("lazyredraw", "o", true)
end
function H.movement_vimopts:restore_all()
    self:restore("lazyredraw", "o")
end

H.scroll_vimopts = vimopts:new()
function H.scroll_vimopts:set_all()
    self:set("virtualedit", "o", "all") -- Use virtual columns for diagonal scrolling.
end
function H.scroll_vimopts:restore_all()
    self:restore("virtualedit", "o")
end

H.get_target_position = function(position, options)
    local target_position = position
    if options.center then
        target_position.winline = math.ceil(vim.api.nvim_win_get_height(0) / 2)
    end
    return target_position
end

return M
