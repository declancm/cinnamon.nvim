local M = {}

M.setup = function()
  local opts = { noremap = true, silent = true }
  local keymap = vim.api.nvim_set_keymap

  Cinnamon = require 'cinnamon.scroll'

  -- Options:
  vim.g.cinnamon_centered = 1

  -- Keymaps:
  if vim.g.cinnamon_no_defaults ~= 1 then
    -- Half-window movements:
    keymap('', '<C-u>', "<Cmd>lua Cinnamon.Scroll('<C-u>')<CR>", opts)
    keymap('', '<C-d>', "<Cmd>lua Cinnamon.Scroll('<C-d>')<CR>", opts)
    keymap('i', '<C-u>', "<Cmd>lua Cinnamon.Scroll('<C-u>')<CR>", opts)
    keymap('i', '<C-d>', "<Cmd>lua Cinnamon.Scroll('<C-d>')<CR>", opts)

    -- Page movements:
    keymap('n', '<C-b>', "<Cmd>lua Cinnamon.Scroll('<C-b>', 1, 1)<CR>", opts)
    keymap('n', '<C-f>', "<Cmd>lua Cinnamon.Scroll('<C-f>', 1, 1)<CR>", opts)
    keymap('n', '<PageUp>', "<Cmd>lua Cinnamon.Scroll('<C-b>', 1, 1)<CR>", opts)
    keymap('n', '<PageDown>', "<Cmd>lua Cinnamon.Scroll('<C-f>', 1, 1)<CR>", opts)

    -- Paragraph movements:
    keymap('n', '{', "<Cmd>lua Cinnamon.Scroll('{', 0)<CR>", opts)
    keymap('n', '}', "<Cmd>lua Cinnamon.Scroll('}', 0)<CR>", opts)
    keymap('x', '{', "<Cmd>lua Cinnamon.Scroll('{', 0)<CR>", opts)
    keymap('x', '}', "<Cmd>lua Cinnamon.Scroll('}', 0)<CR>", opts)

    -- Previous/next search result:
    keymap('n', 'n', "<Cmd>lua Cinnamon.Scroll('n', 1, 0, 3)<CR>", opts)
    keymap('n', 'N', "<Cmd>lua Cinnamon.Scroll('N', 1, 0, 3)<CR>", opts)
    keymap('n', '*', "<Cmd>lua Cinnamon.Scroll('*', 1, 0, 3)<CR>", opts)
    keymap('n', '#', "<Cmd>lua Cinnamon.Scroll('#', 1, 0, 3)<CR>", opts)

    -- Previous cursor location:
    keymap('n', '<C-o>', "<Cmd>lua Cinnamon.Scroll('<C-o>', 1, 0, 3)<CR>", opts)
    keymap('n', '<C-i>', "<Cmd>lua Cinnamon.Scroll('1<C-i>', 1, 0, 3)<CR>", opts)
  end

  if vim.g.cinnamon_extras == 1 then
    -- Line number movements:
    keymap('n', 'gg', "<Cmd>lua Cinnamon.Scroll('gg', 0, 0, 3)<CR>", opts)
    keymap('n', 'G', "<Cmd>lua Cinnamon.Scroll('G', 0, 1, 3)<CR>", opts)
    keymap('x', 'gg', "<Cmd>lua Cinnamon.Scroll('gg', 0, 0, 3)<CR>", opts)
    keymap('x', 'G', "<Cmd>lua Cinnamon.Scroll('G', 0, 1, 3)<CR>", opts)

    -- Up/down movements:
    keymap('n', 'k', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 2, 0)<CR>", opts)
    keymap('n', 'j', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 2, 0)<CR>", opts)
    keymap('n', '<Up>', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 2, 0)<CR>", opts)
    keymap('n', '<Down>', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 2, 0)<CR>", opts)
    keymap('x', 'k', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 2, 0)<CR>", opts)
    keymap('x', 'j', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 2, 0)<CR>", opts)
    keymap('x', '<Up>', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 2, 0)<CR>", opts)
    keymap('x', '<Down>', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 2, 0)<CR>", opts)
  end
end

return M
