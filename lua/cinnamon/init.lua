local M = {}

local map = function(mode, lhs, rhs)
    if type(mode) == "table" then
        for _, value in ipairs(mode) do
            vim.keymap.set(value, lhs, rhs)
        end
    else
        vim.keymap.set(mode, lhs, rhs)
    end
end

M.setup = function(user_config)
    local config = require("cinnamon.config")

    -- Set the config:
    if user_config ~= nil then
        config = vim.tbl_deep_extend("force", config, user_config or {})
    end

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

    local s = require("cinnamon.scroll").scroll

    -- stylua: ignore start
    if config.default_keymaps then
        -- Half-window movements:
        map({ "n", "x" }, "<C-u>", function() s("<C-u>") end)
        map({ "n", "x" }, "<C-d>", function() s("<C-d>") end)

        -- Page movements:
        map({ "n", "x" }, "<C-b>", function() s("<C-b>") end)
        map({ "n", "x" }, "<C-f>", function() s("<C-f>") end)
        map({ "n", "x" }, "<PageUp>", function() s("<PageUp>") end)
        map({ "n", "x" }, "<PageDown>", function() s("<PageDown>") end)
    end

    if config.extra_keymaps then
        -- Start/end of file and line number movements:
        map({ "n", "x" }, "gg", function() s("gg") end)
        map({ "n", "x" }, "G", function() s("G") end)

        -- Start/end of line:
        map({ "n", "x" }, "0", function() s("0") end)
        map({ "n", "x" }, "^", function() s("^") end)
        map({ "n", "x" }, "$", function() s("$") end)

        -- Paragraph movements:
        map({ "n", "x" }, "{", function() s("{") end)
        map({ "n", "x" }, "}", function() s("}") end)

        -- Previous/next search result:
        map("n", "n", function() s("n") end)
        map("n", "N", function() s("N") end)
        map("n", "*", function() s("*") end)
        map("n", "#", function() s("#") end)
        map("n", "g*", function() s("g*") end)
        map("n", "g#", function() s("g#") end)

        -- Previous/next cursor location:
        map("n", "<C-o>", function() s("<C-o>") end)
        map("n", "<C-i>", function() s("<C-i>") end)

        -- Screen scrolling:
        map("n", "zz", function() s("zz") end)
        map("n", "zt", function() s("zt") end)
        map("n", "zb", function() s("zb") end)
        map("n", "z.", function() s("z.") end)
        map("n", "z<CR>", function() s("z<CR>") end)
        map("n", "z-", function() s("z-") end)
        map("n", "z^", function() s("z^") end)
        map("n", "z+", function() s("z+") end)
        map("n", "<C-y>", function() s("<C-y>") end)
        map("n", "<C-e>", function() s("<C-e>") end)

        -- Horizontal screen scrolling:
        map("n", "zh", function() s("zh") end)
        map("n", "zl", function() s("zl") end)
        map("n", "zH", function() s("zH") end)
        map("n", "zL", function() s("zL") end)
        map("n", "zs", function() s("zs") end)
        map("n", "ze", function() s("ze") end)
    end

    if config.extended_keymaps then
        -- Up/down movements:
        map({ "n", "x" }, "k", function() s("k") end)
        map({ "n", "x" }, "j", function() s("j") end)
        map({ "n", "x" }, "<Up>", function() s("<Up>") end)
        map({ "n", "x" }, "<Down>", function() s("<Down>") end)
        map({ "n", "x" }, "gk", function() s("gk") end)
        map({ "n", "x" }, "gj", function() s("gj") end)
        map({ "n", "x" }, "g<Up>", function() s("g<Up>") end)
        map({ "n", "x" }, "g<Down>", function() s("g<Down>") end)

        -- Left/right movements:
        map({ "n", "x" }, "h", function() s("h") end)
        map({ "n", "x" }, "l", function() s("l") end)
        map({ "n", "x" }, "<Left>", function() s("<Left>") end)
        map({ "n", "x" }, "<Right>", function() s("<Right>") end)
    end
    --stylua: ignore end
end

M.scroll = require("cinnamon.scroll").scroll

-- For backward compatibility:
function Scroll(...)
    local args = { ... }

    local command = args[1]
    if command == "definition" then
        command = vim.lsp.buf.definition
    elseif command == "declaration" then
        command = vim.lsp.buf.declaration
    end

    local options = {}
    options.center = args[2] ~= 0
    options.delay = args[4]

    M.scroll(command, options)
end

return M
