local M = {}

local map = function(mode, lhs, rhs)
    if type(mode) == "table" then
        for _, value in ipairs(mode) do
            if vim.fn.maparg(lhs, value) == "" or config.override_keymaps then
                vim.api.nvim_set_keymap(value, lhs, rhs, { noremap = true })
            end
        end
    else
        if vim.fn.maparg(lhs, mode) == "" or config.override_keymaps then
            vim.api.nvim_set_keymap(mode, lhs, rhs, { noremap = true })
        end
    end
end

M.setup = function(user_config)
    local config = require("cinnamon.config")

    -- Set the config:
    if user_config ~= nil then
        vim.tbl_deep_extend("force", config, user_config or {})
    end

    -- Global function used to simplify the keymaps:
    function Scroll(...)
        local args = { ... }

        local command = args[1]
        local options = {}
        options.center = args[2] == 1
        options.delay = args[4]
        require("cinnamon.scroll").scroll(command, options)
    end

    -- Deprecated settings:
    Cinnamon = {}
    Cinnamon.Scroll = Scroll

    -- Create highlight group for hiding cursor:
    if config.hide_cursor and vim.opt.termguicolors:get() then
        vim.cmd([[
    augroup cinnamon_highlight
      autocmd!
      autocmd ColorScheme * highlight CinnamonHideCursor gui=reverse blend=100
    augroup END

    highlight CinnamonHideCursor gui=reverse blend=100
    ]])
    end

    if config.default_keymaps then
        -- Half-window movements:
        map({ "n", "x" }, "<C-u>", "<Cmd>lua Scroll('<C-u>', 1, 1)<CR>")
        map({ "n", "x" }, "<C-d>", "<Cmd>lua Scroll('<C-d>', 1, 1)<CR>")

        -- Page movements:
        map({ "n", "x" }, "<C-b>", "<Cmd>lua Scroll('<C-b>', 0, 1)<CR>")
        map({ "n", "x" }, "<C-f>", "<Cmd>lua Scroll('<C-f>', 0, 1)<CR>")
        map({ "n", "x" }, "<PageUp>", "<Cmd>lua Scroll('<C-b>', 0, 1)<CR>")
        map({ "n", "x" }, "<PageDown>", "<Cmd>lua Scroll('<C-f>', 0, 1)<CR>")
    end

    if config.extra_keymaps then
        -- Start/end of file and line number movements:
        map({ "n", "x" }, "gg", "<Cmd>lua Scroll('gg', 0, 1)<CR>")
        map({ "n", "x" }, "G", "<Cmd>lua Scroll('G', 0, 1)<CR>")

        -- Start/end of line:
        map({ "n", "x" }, "0", "<Cmd>lua Scroll('0')<CR>")
        map({ "n", "x" }, "^", "<Cmd>lua Scroll('^')<CR>")
        map({ "n", "x" }, "$", "<Cmd>lua Scroll('$', 0, 1)<CR>")

        -- Paragraph movements:
        map({ "n", "x" }, "{", "<Cmd>lua Scroll('{')<CR>")
        map({ "n", "x" }, "}", "<Cmd>lua Scroll('}')<CR>")

        -- Previous/next search result:
        map("n", "n", "<Cmd>lua Scroll('n', 1)<CR>")
        map("n", "N", "<Cmd>lua Scroll('N', 1)<CR>")
        map("n", "*", "<Cmd>lua Scroll('*', 1)<CR>")
        map("n", "#", "<Cmd>lua Scroll('#', 1)<CR>")
        map("n", "g*", "<Cmd>lua Scroll('g*', 1)<CR>")
        map("n", "g#", "<Cmd>lua Scroll('g#', 1)<CR>")

        -- Previous/next cursor location:
        map("n", "<C-o>", "<Cmd>lua Scroll('<C-o>', 1)<CR>")
        map("n", "<C-i>", "<Cmd>lua Scroll('1<C-i>', 1)<CR>")

        -- Screen scrolling:
        map("n", "zz", "<Cmd>lua Scroll('zz', 0, 1)<CR>")
        map("n", "zt", "<Cmd>lua Scroll('zt', 0, 1)<CR>")
        map("n", "zb", "<Cmd>lua Scroll('zb', 0, 1)<CR>")
        map("n", "z.", "<Cmd>lua Scroll('z.', 0, 1)<CR>")
        map("n", "z<CR>", "<Cmd>lua Scroll('zt^', 0, 1)<CR>")
        map("n", "z-", "<Cmd>lua Scroll('z-', 0, 1)<CR>")
        map("n", "z^", "<Cmd>lua Scroll('z^', 0, 1)<CR>")
        map("n", "z+", "<Cmd>lua Scroll('z+', 0, 1)<CR>")
        map("n", "<C-y>", "<Cmd>lua Scroll('<C-y>', 0, 1)<CR>")
        map("n", "<C-e>", "<Cmd>lua Scroll('<C-e>', 0, 1)<CR>")

        -- Horizontal screen scrolling:
        map("n", "zh", "<Cmd>lua Scroll('zh', 0, 1)<CR>")
        map("n", "zl", "<Cmd>lua Scroll('zl', 0, 1)<CR>")
        map("n", "zH", "<Cmd>lua Scroll('zH')<CR>")
        map("n", "zL", "<Cmd>lua Scroll('zL')<CR>")
        map("n", "zs", "<Cmd>lua Scroll('zs')<CR>")
        map("n", "ze", "<Cmd>lua Scroll('ze')<CR>")
    end

    if config.extended_keymaps then
        -- Up/down movements:
        map({ "n", "x" }, "k", "<Cmd>lua Scroll('k', 0, 1)<CR>")
        map({ "n", "x" }, "j", "<Cmd>lua Scroll('j', 0, 1)<CR>")
        map({ "n", "x" }, "<Up>", "<Cmd>lua Scroll('<Up>', 0, 1)<CR>")
        map({ "n", "x" }, "<Down>", "<Cmd>lua Scroll('<Down>', 0, 1)<CR>")
        map({ "n", "x" }, "gk", "<Cmd>lua Scroll('gk', 0, 1)<CR>")
        map({ "n", "x" }, "gj", "<Cmd>lua Scroll('gj', 0, 1)<CR>")
        map({ "n", "x" }, "g<Up>", "<Cmd>lua Scroll('g<Up>', 0, 1)<CR>")
        map({ "n", "x" }, "g<Down>", "<Cmd>lua Scroll('g<Down>', 0, 1)<CR>")

        -- Left/right movements:
        map({ "n", "x" }, "h", "<Cmd>lua Scroll('h', 0, 1)<CR>")
        map({ "n", "x" }, "l", "<Cmd>lua Scroll('l', 0, 1)<CR>")
        map({ "n", "x" }, "<Left>", "<Cmd>lua Scroll('<Left>', 0, 1)<CR>")
        map({ "n", "x" }, "<Right>", "<Cmd>lua Scroll('<Right>', 0, 1)<CR>")
    end
end

return M
