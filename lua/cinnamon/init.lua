local config = require("cinnamon.config")
local scroll = require("cinnamon.scroll")
local M = {}

M.scroll = scroll.scroll

---@param user_config? CinnamonOptions
M.setup = function(user_config)
    config.setup(user_config)
    local keymaps = config.get().keymaps

    -- stylua: ignore start
    if keymaps.basic then
        -- Half-window movements:
        vim.keymap.set({ "n", "x" }, "<C-u>", function() M.scroll("<C-u>") end)
        vim.keymap.set({ "n", "x" }, "<C-d>", function() M.scroll("<C-d>") end)

        -- Page movements:
        vim.keymap.set({ "n", "x" }, "<C-b>", function() M.scroll("<C-b>") end)
        vim.keymap.set({ "n", "x" }, "<C-f>", function() M.scroll("<C-f>") end)
        vim.keymap.set({ "n", "x" }, "<PageUp>", function() M.scroll("<PageUp>") end)
        vim.keymap.set({ "n", "x" }, "<PageDown>", function() M.scroll("<PageDown>") end)

        -- Paragraph movements:
        vim.keymap.set({ "n", "x" }, "{", function() M.scroll("{") end)
        vim.keymap.set({ "n", "x" }, "}", function() M.scroll("}") end)

        -- Previous/next search result:
        vim.keymap.set("n", "n", function() M.scroll("n") end)
        vim.keymap.set("n", "N", function() M.scroll("N") end)
        vim.keymap.set("n", "*", function() M.scroll("*") end)
        vim.keymap.set("n", "#", function() M.scroll("#") end)
        vim.keymap.set("n", "g*", function() M.scroll("g*") end)
        vim.keymap.set("n", "g#", function() M.scroll("g#") end)

        -- Previous/next cursor location:
        vim.keymap.set("n", "<C-o>", function() M.scroll("<C-o>") end)
        vim.keymap.set("n", "<C-i>", function() M.scroll("<C-i>") end)

    end

    if keymaps.extra then
        -- Start/end of file and line number movements:
        vim.keymap.set({ "n", "x" }, "gg", function() M.scroll("gg", { delay = 5 }) end)
        vim.keymap.set({ "n", "x" }, "G", function() M.scroll("G", { delay = 5 }) end)

        -- Start/end of line:
        vim.keymap.set({ "n", "x" }, "0", function() M.scroll("0") end)
        vim.keymap.set({ "n", "x" }, "^", function() M.scroll("^") end)
        vim.keymap.set({ "n", "x" }, "$", function() M.scroll("$") end)

        -- Screen scrolling:
        vim.keymap.set("n", "zz", function() M.scroll("zz") end)
        vim.keymap.set("n", "zt", function() M.scroll("zt") end)
        vim.keymap.set("n", "zb", function() M.scroll("zb") end)
        vim.keymap.set("n", "z.", function() M.scroll("z.") end)
        vim.keymap.set("n", "z<CR>", function() M.scroll("z<CR>") end)
        vim.keymap.set("n", "z-", function() M.scroll("z-") end)
        vim.keymap.set("n", "z^", function() M.scroll("z^") end)
        vim.keymap.set("n", "z+", function() M.scroll("z+") end)
        vim.keymap.set("n", "<C-y>", function() M.scroll("<C-y>") end)
        vim.keymap.set("n", "<C-e>", function() M.scroll("<C-e>") end)

        -- Horizontal screen scrolling:
        vim.keymap.set("n", "zh", function() M.scroll("zh") end)
        vim.keymap.set("n", "zl", function() M.scroll("zl") end)
        vim.keymap.set("n", "zH", function() M.scroll("zH") end)
        vim.keymap.set("n", "zL", function() M.scroll("zL") end)
        vim.keymap.set("n", "zs", function() M.scroll("zs") end)
        vim.keymap.set("n", "ze", function() M.scroll("ze") end)

        -- Up/down movements:
        vim.keymap.set({ "n", "x" }, "k", function() M.scroll("k") end)
        vim.keymap.set({ "n", "x" }, "j", function() M.scroll("j") end)
        vim.keymap.set({ "n", "x" }, "<Up>", function() M.scroll("<Up>") end)
        vim.keymap.set({ "n", "x" }, "<Down>", function() M.scroll("<Down>") end)
        vim.keymap.set({ "n", "x" }, "gk", function() M.scroll("gk") end)
        vim.keymap.set({ "n", "x" }, "gj", function() M.scroll("gj") end)
        vim.keymap.set({ "n", "x" }, "g<Up>", function() M.scroll("g<Up>") end)
        vim.keymap.set({ "n", "x" }, "g<Down>", function() M.scroll("g<Down>") end)

        -- Left/right movements:
        vim.keymap.set({ "n", "x" }, "h", function() M.scroll("h") end)
        vim.keymap.set({ "n", "x" }, "l", function() M.scroll("l") end)
        vim.keymap.set({ "n", "x" }, "<Left>", function() M.scroll("<Left>") end)
        vim.keymap.set({ "n", "x" }, "<Right>", function() M.scroll("<Right>") end)
    end
    --stylua: ignore end
end

---@deprecated
function Scroll(...)
    vim.notify_once("[cinnamon] The 'Scroll()' API function is now deprecated. Please use 'require('cinnamon').scroll()' instead.", vim.log.levels.WARN)

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
