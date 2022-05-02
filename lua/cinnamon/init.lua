local M = {}

M.setup = function(user_config)
  local config = require('cinnamon.config')
  local utils = require('cinnamon.utils')

  -- Set the config:
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
      'WARN'
    )
    config.default_keymaps = false
  end

  if vim.g.cinnamon_extras == 1 then
    require('cinnamon.utils').error_msg(
      "Using 'vim.g.cinnamon_extras' is deprecated. Please use \"require('cinnamon').setup { extra_keymaps = true }\" instead",
      'Warning',
      'WARN'
    )
    config.extra_keymaps = true
  end

  -- Global function used to simplify the keymaps:
  function Scroll(...)
    require('cinnamon.scroll').scroll(...)
  end

  if vim.fn.has('nvim-0.7.0') == 1 then
    if config.default_keymaps then
      -- Half-window movements:
      vim.keymap.set({ 'n', 'x', 'i' }, '<C-u>', "<Cmd>lua Scroll('<C-u>')<CR>")
      vim.keymap.set({ 'n', 'x', 'i' }, '<C-d>', "<Cmd>lua Scroll('<C-d>')<CR>")

      -- Page movements:
      vim.keymap.set('n', '<C-b>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>")
      vim.keymap.set('n', '<C-f>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>")
      vim.keymap.set('n', '<PageUp>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>")
      vim.keymap.set('n', '<PageDown>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>")
    end

    if config.extra_keymaps then
      -- Start/end of file and line number movements:
      vim.keymap.set({ 'n', 'x' }, 'gg', "<Cmd>lua Scroll('gg', 0, 0, 3)<CR>")
      vim.keymap.set({ 'n', 'x' }, 'G', "<Cmd>lua Scroll('G', 0, 1, 3)<CR>")

      -- Paragraph movements:
      vim.keymap.set({ 'n', 'x' }, '{', "<Cmd>lua Scroll('{', 0)<CR>")
      vim.keymap.set({ 'n', 'x' }, '}', "<Cmd>lua Scroll('}', 0)<CR>")

      -- Previous/next search result:
      vim.keymap.set('n', 'n', "<Cmd>lua Scroll('n')<CR>")
      vim.keymap.set('n', 'N', "<Cmd>lua Scroll('N')<CR>")
      vim.keymap.set('n', '*', "<Cmd>lua Scroll('*')<CR>")
      vim.keymap.set('n', '#', "<Cmd>lua Scroll('#')<CR>")
      vim.keymap.set('n', 'g*', "<Cmd>lua Scroll('g*')<CR>")
      vim.keymap.set('n', 'g#', "<Cmd>lua Scroll('g#')<CR>")

      -- Previous/next cursor location:
      vim.keymap.set('n', '<C-o>', "<Cmd>lua Scroll('<C-o>')<CR>")
      vim.keymap.set('n', '<C-i>', "<Cmd>lua Scroll('1<C-i>')<CR>")

      -- Screen scrolling:
      vim.keymap.set('n', 'zz', "<Cmd>lua Scroll('zz', 0, 1)<CR>")
      vim.keymap.set('n', 'zt', "<Cmd>lua Scroll('zt', 0, 1)<CR>")
      vim.keymap.set('n', 'zb', "<Cmd>lua Scroll('zb', 0, 1)<CR>")
      vim.keymap.set('n', 'z.', "<Cmd>lua Scroll('z.', 0, 1)<CR>")
      vim.keymap.set('n', 'z<CR>', "<Cmd>lua Scroll('zt^', 0, 1)<CR>")
      vim.keymap.set('n', 'z-', "<Cmd>lua Scroll('z-', 0, 1)<CR>")
      vim.keymap.set('n', 'z^', "<Cmd>lua Scroll('z^', 0, 1)<CR>")
      vim.keymap.set('n', 'z+', "<Cmd>lua Scroll('z+', 0, 1)<CR>")
      vim.keymap.set('n', '<C-y>', "<Cmd>lua Scroll('<C-y>', 0, 1)<CR>")
      vim.keymap.set('n', '<C-e>', "<Cmd>lua Scroll('<C-e>', 0, 1)<CR>")

      -- Horizontal screen scrolling:
      vim.keymap.set('n', 'zh', "<Cmd>lua Scroll('zh', 0, 1)<CR>")
      vim.keymap.set('n', 'zl', "<Cmd>lua Scroll('zl', 0, 1)<CR>")
      vim.keymap.set('n', 'zH', "<Cmd>lua Scroll('zH', 0)<CR>")
      vim.keymap.set('n', 'zL', "<Cmd>lua Scroll('zL', 0)<CR>")
      vim.keymap.set('n', 'zs', "<Cmd>lua Scroll('zs', 0)<CR>")
      vim.keymap.set('n', 'ze', "<Cmd>lua Scroll('ze', 0)<CR>")

      -- Start/end of line:
      vim.keymap.set('n', '0', "<Cmd>lua Scroll('0', 0)<CR>")
      vim.keymap.set('n', '^', "<Cmd>lua Scroll('^', 0)<CR>")
      vim.keymap.set('n', '$', "<Cmd>lua Scroll('$', 0, 1)<CR>")
    end

    if config.extended_keymaps then
      -- Up/down movements:
      vim.keymap.set({ 'n', 'x' }, 'k', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>")
      vim.keymap.set({ 'n', 'x' }, 'j', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>")
      vim.keymap.set({ 'n', 'x' }, '<Up>', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>")
      vim.keymap.set({ 'n', 'x' }, '<Down>', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>")

      -- Left/right movements:
      vim.keymap.set({ 'n', 'x' }, 'h', "<Cmd>lua Scroll('h', 0, 1, 2, 0)<CR>")
      vim.keymap.set({ 'n', 'x' }, 'l', "<Cmd>lua Scroll('l', 0, 1, 2, 0)<CR>")
      vim.keymap.set({ 'n', 'x' }, '<Left>', "<Cmd>lua Scroll('h', 0, 1, 2, 0)<CR>")
      vim.keymap.set({ 'n', 'x' }, '<Right>', "<Cmd>lua Scroll('l', 0, 1, 2, 0)<CR>")
    end
  else
    local opts = { noremap = true, silent = true }
    local keymap = vim.api.nvim_set_keymap

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

      -- Window scrolling:
      keymap('n', 'zz', "<Cmd>lua Scroll('zz', 0, 1)<CR>", opts)
      keymap('n', 'zt', "<Cmd>lua Scroll('zt', 0, 1)<CR>", opts)
      keymap('n', 'zb', "<Cmd>lua Scroll('zb', 0, 1)<CR>", opts)
      keymap('n', 'z.', "<Cmd>lua Scroll('z.', 0, 1)<CR>", opts)
      keymap('n', 'z<CR>', "<Cmd>lua Scroll('zt^', 0, 1)<CR>", opts)
      keymap('n', 'z-', "<Cmd>lua Scroll('z-', 0, 1)<CR>", opts)
      keymap('n', 'z^', "<Cmd>lua Scroll('z^', 0, 1)<CR>", opts)
      keymap('n', 'z+', "<Cmd>lua Scroll('z+', 0, 1)<CR>", opts)
      keymap('n', '<C-y>', "<Cmd>lua Scroll('<C-y>', 0, 1)<CR>", opts)
      keymap('n', '<C-e>', "<Cmd>lua Scroll('<C-e>', 0, 1)<CR>", opts)

      -- Horizontal screen scrolling:
      keymap('n', 'zh', "<Cmd>lua Scroll('zh', 0, 1)<CR>", opts)
      keymap('n', 'zl', "<Cmd>lua Scroll('zl', 0, 1)<CR>", opts)
      keymap('n', 'zH', "<Cmd>lua Scroll('zH', 0)<CR>", opts)
      keymap('n', 'zL', "<Cmd>lua Scroll('zL', 0)<CR>", opts)
      keymap('n', 'zs', "<Cmd>lua Scroll('zs', 0)<CR>", opts)
      keymap('n', 'ze', "<Cmd>lua Scroll('ze', 0)<CR>", opts)

      -- Start/end of line:
      keymap('n', '0', "<Cmd>lua Scroll('0', 0)<CR>", opts)
      keymap('n', '^', "<Cmd>lua Scroll('^', 0)<CR>", opts)
      keymap('n', '$', "<Cmd>lua Scroll('$', 0)<CR>", opts)
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

      -- Left/right movements:
      keymap('n', 'h', "<Cmd>lua Scroll('h', 0, 1, 2, 0)<CR>", opts)
      keymap('x', 'h', "<Cmd>lua Scroll('h', 0, 1, 2, 0)<CR>", opts)
      keymap('n', 'l', "<Cmd>lua Scroll('l', 0, 1, 2, 0)<CR>", opts)
      keymap('x', 'l', "<Cmd>lua Scroll('l', 0, 1, 2, 0)<CR>", opts)
      keymap('n', '<Left>', "<Cmd>lua Scroll('h', 0, 1, 2, 0)<CR>", opts)
      keymap('x', '<Left>', "<Cmd>lua Scroll('h', 0, 1, 2, 0)<CR>", opts)
      keymap('n', '<Right>', "<Cmd>lua Scroll('l', 0, 1, 2, 0)<CR>", opts)
      keymap('x', '<Right>', "<Cmd>lua Scroll('l', 0, 1, 2, 0)<CR>", opts)
    end
  end
end

-- API:

M.Scroll = function(...)
  require('cinnamon.scroll').scroll(...)
end

return M
