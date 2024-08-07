local config = require("cinnamon.config")
local scroll = require("cinnamon.scroll")
local utils = require("cinnamon.utils")
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
        -- TODO: Remove callbacks once conflict with noice.nvim is resolved. See #50
        local next_search_cb = function()
            if package.loaded["noice"] then
                vim.schedule(function()
                    pcall(vim.cmd.normal, { "Nn", bang = true, mods = { keepjumps = true } })
                end)
            end
        end
        local prev_search_cb = function()
            if package.loaded["noice"] then
                vim.schedule(function()
                    pcall(vim.cmd.normal, { "nN", bang = true, mods = { keepjumps = true } })
                end)
            end
        end
        vim.keymap.set("n", "n", function() M.scroll("n", { _weak_callback = next_search_cb }) end)
        vim.keymap.set("n", "N", function() M.scroll("N", { _weak_callback = prev_search_cb }) end)
        vim.keymap.set("n", "*", function() M.scroll("*", { _weak_callback = next_search_cb }) end)
        vim.keymap.set("n", "#", function() M.scroll("#", { _weak_callback = prev_search_cb }) end)
        vim.keymap.set("n", "g*", function() M.scroll("g*", { _weak_callback = next_search_cb }) end)
        vim.keymap.set("n", "g#", function() M.scroll("g#", { _weak_callback = prev_search_cb }) end)

        -- Previous/next cursor location:
        vim.keymap.set("n", "<C-o>", function() M.scroll("<C-o>") end)
        vim.keymap.set("n", "<C-i>", function() M.scroll("<C-S-i>") end)

    end

    if keymaps.extra then
        -- Start/end of file and line number movements:
        vim.keymap.set({ "n", "x" }, "gg", function() M.scroll("gg") end)
        vim.keymap.set({ "n", "x" }, "G", function() M.scroll("G") end)

        -- Start/end of line:
        vim.keymap.set({ "n", "x" }, "0", function() M.scroll("0") end)
        vim.keymap.set({ "n", "x" }, "^", function() M.scroll("^") end)
        vim.keymap.set({ "n", "x" }, "$", function() M.scroll("$") end)

        -- Screen scrolling:
        vim.keymap.set({ "n", "x" }, "zz", function() M.scroll("zz") end)
        vim.keymap.set({ "n", "x" }, "zt", function() M.scroll("zt") end)
        vim.keymap.set({ "n", "x" }, "zb", function() M.scroll("zb") end)
        vim.keymap.set({ "n", "x" }, "z.", function() M.scroll("z.") end)
        vim.keymap.set({ "n", "x" }, "z<CR>", function() M.scroll("z<CR>") end)
        vim.keymap.set({ "n", "x" }, "z-", function() M.scroll("z-") end)
        vim.keymap.set({ "n", "x" }, "z^", function() M.scroll("z^") end)
        vim.keymap.set({ "n", "x" }, "z+", function() M.scroll("z+") end)
        vim.keymap.set({ "n", "x" }, "<C-y>", function() M.scroll("<C-y>", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "<C-e>", function() M.scroll("<C-e>", { count_only = true }) end)

        -- Horizontal screen scrolling:
        vim.keymap.set({ "n", "x" }, "zh", function() M.scroll("zh", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "zl", function() M.scroll("zl", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "zH", function() M.scroll("zH") end)
        vim.keymap.set({ "n", "x" }, "zL", function() M.scroll("zL") end)
        vim.keymap.set({ "n", "x" }, "zs", function() M.scroll("zs") end)
        vim.keymap.set({ "n", "x" }, "ze", function() M.scroll("ze") end)

        -- Up/down movements:
        vim.keymap.set({ "n", "x" }, "k", function() M.scroll("k", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "j", function() M.scroll("j", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "<Up>", function() M.scroll("<Up>", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "<Down>", function() M.scroll("<Down>", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "gk", function() M.scroll("gk", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "gj", function() M.scroll("gj", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "g<Up>", function() M.scroll("g<Up>", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "g<Down>", function() M.scroll("g<Down>", { count_only = true }) end)

        -- Left/right movements:
        vim.keymap.set({ "n", "x" }, "h", function() M.scroll("h", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "l", function() M.scroll("l", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "<Left>", function() M.scroll("<Left>", { count_only = true }) end)
        vim.keymap.set({ "n", "x" }, "<Right>", function() M.scroll("<Right>", { count_only = true }) end)
    end
    --stylua: ignore end
end

---@deprecated
function Scroll(...)
    utils.notify(
        "The 'Scroll()' API function is now deprecated. Please use 'require('cinnamon').scroll()' instead",
        "warn",
        { once = true }
    )

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
