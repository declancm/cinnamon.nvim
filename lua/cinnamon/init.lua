local M = {}

M.setup = function(user_config)
  local config = require('cinnamon.config')
  local utils = require('cinnamon.utils')

  -- Set the config:
  if user_config ~= nil then
    utils.merge(config, user_config)
  end

  -- Global function used to simplify the keymaps:
  function Scroll(...)
    require('cinnamon.scroll').scroll(...)
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
    utils.create_keymap({ 'n', 'x' }, '<C-u>', "<Cmd>lua Scroll('<C-u>', 1, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, '<C-d>', "<Cmd>lua Scroll('<C-d>', 1, 1)<CR>")

    -- Page movements:
    utils.create_keymap({ 'n', 'x' }, '<C-b>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, '<C-f>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, '<PageUp>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, '<PageDown>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>")
  end

  if config.extra_keymaps then
    -- Start/end of file and line number movements:
    utils.create_keymap({ 'n', 'x' }, 'gg', "<Cmd>lua Scroll('gg', 0, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, 'G', "<Cmd>lua Scroll('G', 0, 1)<CR>")

    -- Start/end of line:
    utils.create_keymap({ 'n', 'x' }, '0', "<Cmd>lua Scroll('0')<CR>")
    utils.create_keymap({ 'n', 'x' }, '^', "<Cmd>lua Scroll('^')<CR>")
    utils.create_keymap({ 'n', 'x' }, '$', "<Cmd>lua Scroll('$', 0, 1)<CR>")

    -- Paragraph movements:
    utils.create_keymap({ 'n', 'x' }, '{', "<Cmd>lua Scroll('{')<CR>")
    utils.create_keymap({ 'n', 'x' }, '}', "<Cmd>lua Scroll('}')<CR>")

    -- Previous/next search result:
    utils.create_keymap('n', 'n', "<Cmd>lua Scroll('n', 1)<CR>")
    utils.create_keymap('n', 'N', "<Cmd>lua Scroll('N', 1)<CR>")
    utils.create_keymap('n', '*', "<Cmd>lua Scroll('*', 1)<CR>")
    utils.create_keymap('n', '#', "<Cmd>lua Scroll('#', 1)<CR>")
    utils.create_keymap('n', 'g*', "<Cmd>lua Scroll('g*', 1)<CR>")
    utils.create_keymap('n', 'g#', "<Cmd>lua Scroll('g#', 1)<CR>")

    -- Previous/next cursor location:
    utils.create_keymap('n', '<C-o>', "<Cmd>lua Scroll('<C-o>', 1)<CR>")
    utils.create_keymap('n', '<C-i>', "<Cmd>lua Scroll('1<C-i>', 1)<CR>")

    -- Screen scrolling:
    utils.create_keymap('n', 'zz', "<Cmd>lua Scroll('zz', 0, 1)<CR>")
    utils.create_keymap('n', 'zt', "<Cmd>lua Scroll('zt', 0, 1)<CR>")
    utils.create_keymap('n', 'zb', "<Cmd>lua Scroll('zb', 0, 1)<CR>")
    utils.create_keymap('n', 'z.', "<Cmd>lua Scroll('z.', 0, 1)<CR>")
    utils.create_keymap('n', 'z<CR>', "<Cmd>lua Scroll('zt^', 0, 1)<CR>")
    utils.create_keymap('n', 'z-', "<Cmd>lua Scroll('z-', 0, 1)<CR>")
    utils.create_keymap('n', 'z^', "<Cmd>lua Scroll('z^', 0, 1)<CR>")
    utils.create_keymap('n', 'z+', "<Cmd>lua Scroll('z+', 0, 1)<CR>")
    utils.create_keymap('n', '<C-y>', "<Cmd>lua Scroll('<C-y>', 0, 1)<CR>")
    utils.create_keymap('n', '<C-e>', "<Cmd>lua Scroll('<C-e>', 0, 1)<CR>")

    -- Horizontal screen scrolling:
    utils.create_keymap('n', 'zh', "<Cmd>lua Scroll('zh', 0, 1)<CR>")
    utils.create_keymap('n', 'zl', "<Cmd>lua Scroll('zl', 0, 1)<CR>")
    utils.create_keymap('n', 'zH', "<Cmd>lua Scroll('zH')<CR>")
    utils.create_keymap('n', 'zL', "<Cmd>lua Scroll('zL')<CR>")
    utils.create_keymap('n', 'zs', "<Cmd>lua Scroll('zs')<CR>")
    utils.create_keymap('n', 'ze', "<Cmd>lua Scroll('ze')<CR>")
  end

  if config.extended_keymaps then
    -- Up/down movements:
    utils.create_keymap({ 'n', 'x' }, 'k', "<Cmd>lua Scroll('k', 0, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, 'j', "<Cmd>lua Scroll('j', 0, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, '<Up>', "<Cmd>lua Scroll('k', 0, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, '<Down>', "<Cmd>lua Scroll('j', 0, 1)<CR>")

    -- Left/right movements:
    utils.create_keymap({ 'n', 'x' }, 'h', "<Cmd>lua Scroll('h', 0, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, 'l', "<Cmd>lua Scroll('l', 0, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, '<Left>', "<Cmd>lua Scroll('h', 0, 1)<CR>")
    utils.create_keymap({ 'n', 'x' }, '<Right>', "<Cmd>lua Scroll('l', 0, 1)<CR>")
  end
end

return M
