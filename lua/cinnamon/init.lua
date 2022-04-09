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
  Cinnamon = require('cinnamon')

  if vim.g.cinnamon_no_defaults == 1 then
    require('cinnamon.utils').error_msg(
      "Using 'vim.g.cinnamon_no_defaults' is deprecated. Please use \"require('cinnamon').setup { default_keymaps = false }\" instead",
      'Warning',
      'WarningMsg'
    )
    config.default_keymaps = false
  end

  if vim.g.cinnamon_extras == 1 then
    require('cinnamon.utils').error_msg(
      "Using 'vim.g.cinnamon_extras' is deprecated. Please use \"require('cinnamon').setup { extra_keymaps = true }\" instead",
      'Warning',
      'WarningMsg'
    )
    config.extra_keymaps = true
  end

  -- Global variable used to simplify the keymaps:
  Scroll = require('cinnamon').Scroll

  local opts = { noremap = true, silent = true }
  local keymap = vim.api.nvim_set_keymap

  -- Keymaps:
  if config.default_keymaps then
    -- Half-window movements:
    keymap('', '<C-u>', "<Cmd>lua Scroll('<C-u>')<CR>", opts)
    keymap('i', '<C-u>', "<Cmd>lua Scroll('<C-u>')<CR>", opts)
    keymap('', '<C-d>', "<Cmd>lua Scroll('<C-d>')<CR>", opts)
    keymap('i', '<C-d>', "<Cmd>lua Scroll('<C-d>')<CR>", opts)

    -- Page movements:
    keymap('n', '<C-b>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>", opts)
    keymap('n', '<C-f>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>", opts)
    keymap('n', '<PageUp>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>", opts)
    keymap('n', '<PageDown>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>", opts)
  end

  if config.extra_keymaps then
    -- Start/end of file and line number movements:
    keymap('n', 'gg', "<Cmd>lua Scroll('gg', 0, 0, 3)<CR>", opts)
    keymap('x', 'gg', "<Cmd>lua Scroll('gg', 0, 0, 3)<CR>", opts)
    keymap('n', 'G', "<Cmd>lua Scroll('G', 0, 1, 3)<CR>", opts)
    keymap('x', 'G', "<Cmd>lua Scroll('G', 0, 1, 3)<CR>", opts)

    -- Paragraph movements:
    keymap('n', '{', "<Cmd>lua Scroll('{', 0)<CR>", opts)
    keymap('x', '{', "<Cmd>lua Scroll('{', 0)<CR>", opts)
    keymap('n', '}', "<Cmd>lua Scroll('}', 0)<CR>", opts)
    keymap('x', '}', "<Cmd>lua Scroll('}', 0)<CR>", opts)

    -- Previous/next search result:
    keymap('n', 'n', "<Cmd>lua Scroll('n')<CR>", opts)
    keymap('n', 'N', "<Cmd>lua Scroll('N')<CR>", opts)
    keymap('n', '*', "<Cmd>lua Scroll('*')<CR>", opts)
    keymap('n', '#', "<Cmd>lua Scroll('#')<CR>", opts)
    keymap('n', 'g*', "<Cmd>lua Scroll('g*')<CR>", opts)
    keymap('n', 'g#', "<Cmd>lua Scroll('g#')<CR>", opts)

    -- Previous/next cursor location:
    keymap('n', '<C-o>', "<Cmd>lua Scroll('<C-o>')<CR>", opts)
    keymap('n', '<C-i>', "<Cmd>lua Scroll('1<C-i>')<CR>", opts)

    -- TODO: find a way for the z<CR> keymap to work

    -- Window scrolling:
    keymap('n', 'zz', "<Cmd>lua Scroll('zz', 1, 1)<CR>", opts)
    keymap('n', 'z.', "<Cmd>lua Scroll('z.', 1, 1)<CR>", opts)
    keymap('n', 'zt', "<Cmd>lua Scroll('zt', 1, 1)<CR>", opts)
    -- keymap('n', 'z<CR>', "<Cmd>lua Scroll('z<CR>', 1, 1)<CR>", opts)
    keymap('n', 'zb', "<Cmd>lua Scroll('zb', 1, 1)<CR>", opts)
    -- keymap('n', 'z-', "<Cmd>lua Scroll('z-', 1, 1)<CR>", opts)
  end

  if config.extended_keymaps then
    -- Up/down movements:
    keymap('n', 'k', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>", opts)
    keymap('x', 'k', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>", opts)
    keymap('n', 'j', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>", opts)
    keymap('x', 'j', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>", opts)
    keymap('n', '<Up>', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>", opts)
    keymap('x', '<Up>', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>", opts)
    keymap('n', '<Down>', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>", opts)
    keymap('x', '<Down>', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>", opts)
  end
end

-- API:

M.Scroll = require('cinnamon.scroll').scroll

return M
