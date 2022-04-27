# Cinnamon Scroll 🌀

Smooth scrolling for __ANY__ movement command (or string of commands) 🤯. A
highly customizable Neovim plugin written in Lua which doesn't break the
single-repeat "." command (unlike some other plugins) and supports scrolling
over folds.

__New Features:__
* Support for the go-to-definition and go-to-declaration builtin LSP functions 🥳🎉.
* Horizontal scrolling for horizontal movements.

__Petition for a cinnamon roll emoji:__<https://www.change.org/p/apple-cinnamon-roll-emoji>

## 📦 Installation

Just install with your favorite package manager and run the setup function.

### Packer

```lua
use {
  'declancm/cinnamon.nvim',
  config = function() require('cinnamon').setup() end
}
```

## ⚙️ Configuration

A settings table can be passed into the setup function for custom options.

### Default Settings

```lua
default_keymaps = true,   -- Create default keymaps.
extra_keymaps = false,    -- Create extra keymaps.
extended_keymaps = false, -- Create extended keymaps.
centered = true,    -- Keep cursor centered in window when using window scrolling.
default_delay = 5,  -- The default delay (in ms) between lines when scrolling.
scroll_limit = 150, -- Max number of lines moved before scrolling is skipped.
```

### Example Configuration

```lua
require('cinnamon').setup {
  extra_keymaps = true,
  scroll_limit = 100,
}
```

## ⌨️ Keymaps

### Default Keymaps

```
Smooth scrolling for ...

Half-window movements:      <C-U> and <C-D>
Page movements:             <C-B>, <C-F>, <PageUp> and <PageDown>
```

### Extra Keymaps

```
Smooth scrolling for ...

Start/end of file:          gg and G
Line number:                [count]G
Paragraph movements:        { and }
Prev/next search result:    n, N, *, #, g* and g#
Prev/next cursor location:  <C-O> and <C-I>
Screen scrolling:           zz, zt, zb, z., z<CR>, z-, z^, z+, [count]<C-Y> and [count]<C-E>
Horizontal scrolling:       [count]zh, [count]zl, zH, zL, zs and ze  
```

### Extended Keymaps

```
Smooth scrolling for ...

Up/down movements:          [count]j, [count]k, [count]<Up> and [count]<Down>
Left/right movements:       [count]h, [count]l, [count]<Left> and [count]<Right>
```

## ℹ️ API

```lua
Scroll(arg1, arg2, arg3, arg4, arg5)
```

* __arg1__ = A string containing the normal mode movement commands.
  * To use the go-to-definition LSP function, use 'definition' (or 'declaration'
    for go-to-declaration).
* __arg2__ = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
* __arg3__ = Accept a count before the command (1 for on, 0 for off). Default is 0.
* __arg4__ = Length of delay between lines (in ms). Default is the 'default_delay' config value.
* __arg5__ = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

_Note: arg1 is a string while the others are ints._

### Keymaps

```lua
-- DEFAULT_KEYMAPS:

-- Half-window movements:
vim.keymap.set({ 'n', 'x', 'i' }, '<C-u>', "<Cmd>lua Scroll('<C-u>')<CR>")
vim.keymap.set({ 'n', 'x', 'i' }, '<C-d>', "<Cmd>lua Scroll('<C-d>')<CR>")

-- Page movements:
vim.keymap.set('n', '<C-b>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>")
vim.keymap.set('n', '<C-f>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>")
vim.keymap.set('n', '<PageUp>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>")
vim.keymap.set('n', '<PageDown>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>")

-- EXTRA_KEYMAPS:

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
vim.keymap.set('n', 'zh', "<Cmd>lua Scroll('zh', 0, 1, 2, 0)<CR>")
vim.keymap.set('n', 'zl', "<Cmd>lua Scroll('zl', 0, 1, 2, 0)<CR>")
vim.keymap.set('n', 'zH', "<Cmd>lua Scroll('zH', 0, 0, 2, 0)<CR>")
vim.keymap.set('n', 'zL', "<Cmd>lua Scroll('zL', 0, 0, 2, 0)<CR>")
vim.keymap.set('n', 'zs', "<Cmd>lua Scroll('zs', 0, 0, 2, 0)<CR>")
vim.keymap.set('n', 'ze', "<Cmd>lua Scroll('ze', 0, 0, 2, 0)<CR>")

-- EXTENDED_KEYMAPS:

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

-- LSP_KEYMAPS:

-- LSP go-to-definition:
vim.keymap.set('n', 'gd', "<Cmd>lua Scroll('definition')<CR>")

-- LSP go-to-declaration:
vim.keymap.set('n', 'gD', "<Cmd>lua Scroll('declaration')<CR>")
```

### Custom Keymaps

If creating a custom keymap which is within the preset keymaps, make sure they 
are disabled so yours isn't overridden.

```lua
-- Disabling the default keymaps.
require('cinnamon').setup { default_keymaps = false }

-- Customizing keymaps that are part of the default mappings.
vim.keymap.set({ 'n', 'x', 'i' }, '<C-u>', "<Cmd>lua Scroll('<C-u>', 1, 0, 7)<CR>")
vim.keymap.set({ 'n', 'x', 'i' }, '<C-d>', "<Cmd>lua Scroll('<C-d>', 1, 0, 7)<CR>")
```
