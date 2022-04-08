local M = {}
local config = require('cinnamon.config')
local utils = require('cinnamon.utils')

M.setup = function(user_config)
  vim.g.__cinnamon_setup_loaded = 1

  if user_config ~= nil then
    utils.merge(config, user_config)
  end

  -- Disable plugin:
  if config.disable then
    return
  end

  -- Deprecated settings:
  if vim.g.cinnamon_no_defaults == 1 then
    require('cinnamon.utils').ErrorMsg(
      "Using 'vim.g.cinnamon_no_defaults' is deprecated. Please use \"require('cinnamon').setup { default_keymaps = false }\" instead",
      'Warning',
      'WarningMsg'
    )
    config.default_keymaps = false
  end

  if vim.g.cinnamon_extras == 1 then
    require('cinnamon.utils').ErrorMsg(
      "Using 'vim.g.cinnamon_extras' is deprecated. Please use \"require('cinnamon').setup { extra_keymaps = true }\" instead",
      'Warning',
      'WarningMsg'
    )
    config.extra_keymaps = true
  end

  -- Global variable used to simplify the keymaps:
  Cinnamon = require('cinnamon.scroll')

  local opts = { noremap = true, silent = true }
  local keymap = vim.api.nvim_set_keymap

  -- Keymaps:
  if config.default_keymaps then
    -- zz, zt, zb
    keymap('n', 'zz', "<Cmd>lua Cinnamon.Scroll('zz')<CR>", opts)
    keymap('n', 'zt', "<Cmd>lua Cinnamon.Scroll('zt')<CR>", opts)
    keymap('n', 'zb', "<Cmd>lua Cinnamon.Scroll('zb')<CR>", opts)

    -- Half-window movements:
    keymap('', '<C-u>', "<Cmd>lua Cinnamon.Scroll('<C-u>')<CR>", opts)
    keymap('i', '<C-u>', "<Cmd>lua Cinnamon.Scroll('<C-u>')<CR>", opts)
    keymap('', '<C-d>', "<Cmd>lua Cinnamon.Scroll('<C-d>')<CR>", opts)
    keymap('i', '<C-d>', "<Cmd>lua Cinnamon.Scroll('<C-d>')<CR>", opts)

    -- Page movements:
    keymap('n', '<C-b>', "<Cmd>lua Cinnamon.Scroll('<C-b>', 1, 1)<CR>", opts)
    keymap('n', '<C-f>', "<Cmd>lua Cinnamon.Scroll('<C-f>', 1, 1)<CR>", opts)
    keymap('n', '<PageUp>', "<Cmd>lua Cinnamon.Scroll('<C-b>', 1, 1)<CR>", opts)
    keymap('n', '<PageDown>', "<Cmd>lua Cinnamon.Scroll('<C-f>', 1, 1)<CR>", opts)
  end

  if config.extra_keymaps then
    -- Start/end of file and line number movements:
    keymap('n', 'gg', "<Cmd>lua Cinnamon.Scroll('gg', 0, 0, 3)<CR>", opts)
    keymap('x', 'gg', "<Cmd>lua Cinnamon.Scroll('gg', 0, 0, 3)<CR>", opts)
    keymap('n', 'G', "<Cmd>lua Cinnamon.Scroll('G', 0, 1, 3)<CR>", opts)
    keymap('x', 'G', "<Cmd>lua Cinnamon.Scroll('G', 0, 1, 3)<CR>", opts)

    -- Paragraph movements:
    keymap('n', '{', "<Cmd>lua Cinnamon.Scroll('{', 0)<CR>", opts)
    keymap('x', '{', "<Cmd>lua Cinnamon.Scroll('{', 0)<CR>", opts)
    keymap('n', '}', "<Cmd>lua Cinnamon.Scroll('}', 0)<CR>", opts)
    keymap('x', '}', "<Cmd>lua Cinnamon.Scroll('}', 0)<CR>", opts)

    -- keymap("n", "zz", "<Cmd>lua Cinnamon.Scroll('zz')<CR>", opts)
    -- keymap("n", "zt", "<Cmd>lua Cinnamon.Scroll('zt', 1, 30)<CR>", opts)
    -- keymap("n", "zb", "<Cmd>lua Cinnamon.Scroll('zb', 1, 30)<CR>", opts)

    -- Previous/next search result:
    keymap('n', 'n', "<Cmd>lua Cinnamon.Scroll('n')<CR>", opts)
    keymap('n', 'N', "<Cmd>lua Cinnamon.Scroll('N')<CR>", opts)
    keymap('n', '*', "<Cmd>lua Cinnamon.Scroll('*')<CR>", opts)
    keymap('n', '#', "<Cmd>lua Cinnamon.Scroll('#')<CR>", opts)
    keymap('n', 'g*', "<Cmd>lua Cinnamon.Scroll('g*')<CR>", opts)
    keymap('n', 'g#', "<Cmd>lua Cinnamon.Scroll('g#')<CR>", opts)

    -- Previous/next cursor location:
    keymap('n', '<C-o>', "<Cmd>lua Cinnamon.Scroll('<C-o>')<CR>", opts)
    keymap('n', '<C-i>', "<Cmd>lua Cinnamon.Scroll('1<C-i>')<CR>", opts)
  end

  if config.extended_keymaps then
    -- Up/down movements:
    keymap('n', 'k', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 3, 0)<CR>", opts)
    keymap('x', 'k', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 3, 0)<CR>", opts)
    keymap('n', 'j', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 3, 0)<CR>", opts)
    keymap('x', 'j', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 3, 0)<CR>", opts)
    keymap('n', '<Up>', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 3, 0)<CR>", opts)
    keymap('x', '<Up>', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 3, 0)<CR>", opts)
    keymap('n', '<Down>', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 3, 0)<CR>", opts)
    keymap('x', '<Down>', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 3, 0)<CR>", opts)
  end
end

return M
