local M = {}

M.setup = function(user_config)
    local config = require("cinnamon.config")

    -- Set the config:
    if user_config ~= nil then
        config = vim.tbl_deep_extend("force", config, user_config or {})
    end

    local s = require("cinnamon.scroll").scroll

    -- stylua: ignore start
    if config.default_keymaps then
        -- Half-window movements:
        vim.keymap.set({ "n", "x" }, "<C-u>", function() s("<C-u>") end)
        vim.keymap.set({ "n", "x" }, "<C-d>", function() s("<C-d>") end)

        -- Page movements:
        vim.keymap.set({ "n", "x" }, "<C-b>", function() s("<C-b>") end)
        vim.keymap.set({ "n", "x" }, "<C-f>", function() s("<C-f>") end)
        vim.keymap.set({ "n", "x" }, "<PageUp>", function() s("<PageUp>") end)
        vim.keymap.set({ "n", "x" }, "<PageDown>", function() s("<PageDown>") end)
    end

    if config.extra_keymaps then
        -- Start/end of file and line number movements:
        vim.keymap.set({ "n", "x" }, "gg", function() s("gg") end)
        vim.keymap.set({ "n", "x" }, "G", function() s("G") end)

        -- Start/end of line:
        vim.keymap.set({ "n", "x" }, "0", function() s("0") end)
        vim.keymap.set({ "n", "x" }, "^", function() s("^") end)
        vim.keymap.set({ "n", "x" }, "$", function() s("$") end)

        -- Paragraph movements:
        vim.keymap.set({ "n", "x" }, "{", function() s("{") end)
        vim.keymap.set({ "n", "x" }, "}", function() s("}") end)

        -- Previous/next search result:
        vim.keymap.set("n", "n", function() s("n") end)
        vim.keymap.set("n", "N", function() s("N") end)
        vim.keymap.set("n", "*", function() s("*") end)
        vim.keymap.set("n", "#", function() s("#") end)
        vim.keymap.set("n", "g*", function() s("g*") end)
        vim.keymap.set("n", "g#", function() s("g#") end)

        -- Previous/next cursor location:
        vim.keymap.set("n", "<C-o>", function() s("<C-o>") end)
        vim.keymap.set("n", "<C-i>", function() s("<C-i>") end)

        -- Screen scrolling:
        vim.keymap.set("n", "zz", function() s("zz") end)
        vim.keymap.set("n", "zt", function() s("zt") end)
        vim.keymap.set("n", "zb", function() s("zb") end)
        vim.keymap.set("n", "z.", function() s("z.") end)
        vim.keymap.set("n", "z<CR>", function() s("z<CR>") end)
        vim.keymap.set("n", "z-", function() s("z-") end)
        vim.keymap.set("n", "z^", function() s("z^") end)
        vim.keymap.set("n", "z+", function() s("z+") end)
        vim.keymap.set("n", "<C-y>", function() s("<C-y>") end)
        vim.keymap.set("n", "<C-e>", function() s("<C-e>") end)

        -- Horizontal screen scrolling:
        vim.keymap.set("n", "zh", function() s("zh") end)
        vim.keymap.set("n", "zl", function() s("zl") end)
        vim.keymap.set("n", "zH", function() s("zH") end)
        vim.keymap.set("n", "zL", function() s("zL") end)
        vim.keymap.set("n", "zs", function() s("zs") end)
        vim.keymap.set("n", "ze", function() s("ze") end)
    end

    if config.extended_keymaps then
        -- Up/down movements:
        vim.keymap.set({ "n", "x" }, "k", function() s("k") end)
        vim.keymap.set({ "n", "x" }, "j", function() s("j") end)
        vim.keymap.set({ "n", "x" }, "<Up>", function() s("<Up>") end)
        vim.keymap.set({ "n", "x" }, "<Down>", function() s("<Down>") end)
        vim.keymap.set({ "n", "x" }, "gk", function() s("gk") end)
        vim.keymap.set({ "n", "x" }, "gj", function() s("gj") end)
        vim.keymap.set({ "n", "x" }, "g<Up>", function() s("g<Up>") end)
        vim.keymap.set({ "n", "x" }, "g<Down>", function() s("g<Down>") end)

        -- Left/right movements:
        vim.keymap.set({ "n", "x" }, "h", function() s("h") end)
        vim.keymap.set({ "n", "x" }, "l", function() s("l") end)
        vim.keymap.set({ "n", "x" }, "<Left>", function() s("<Left>") end)
        vim.keymap.set({ "n", "x" }, "<Right>", function() s("<Right>") end)
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
    options.delay = args[4]

    M.scroll(command, options)
end

return M
