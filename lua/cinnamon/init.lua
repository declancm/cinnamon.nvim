local M = {}

M.setup = function(options)
  if options == nil then
    options = {}
  end

  -- Default values:
  local defaults = {
    default_keymaps = true,
    extra_keymaps = false,
    centered = true,
    scroll_limit = 150,
  }

  -- Generate the options table:
  for key, value in pairs(defaults) do
    if options[key] == nil then
      options[key] = value
    end
  end

  -- Deprecated settings:
  if vim.g.cinnamon_no_defaults == 1 then
    print "Using 'vim.g.cinnamon_no_defaults' is now deprecated :(. Please use \"require('cinnamon').setup { default_keymaps = false }\" instead."
    options['default_keymaps'] = false
  end
  if vim.g.cinnamon_extras == 1 then
    print "Using 'vim.g.cinnamon_extras' is now deprecated :(. Please use \"require('cinnamon').setup { extra_keymaps = true }\" instead."
    options['cinnamon_extras'] = true
  end

  local opts = { noremap = true, silent = true }
  local keymap = vim.api.nvim_set_keymap

  Cinnamon = require 'cinnamon.scroll'

  -- Variables:
  vim.g.__cinnamon_centered = options.centered
  vim.g.__cinnamon_scroll_limit = options.scroll_limit

  -- Keymaps:
  if options.default_keymaps == true then
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

  if options.extra_keymaps == true then
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

  vim.g.__cinnamon_setup_completed = 1
end

return M
