# Cinnamon Scroll 🌀

Smooth scrolling for __ANY__ movement command (or string of commands) 🤯. A
highly customizable Neovim plugin written in Lua which doesn't break the
single-repeat "." command (unlike some other plugins) and supports scrolling
over folds.

__New Features:__
* Support for the go-to-definition and go-to-declaration builtin LSP functions 🥳🎉.
* Smooth horizontal scrolling when view has shifted left or right.
* Smooth scrolling for the scroll wheel.

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
-- KEYMAPS:
default_keymaps = true,   -- Create default keymaps.
extra_keymaps = false,    -- Create extra keymaps.
extended_keymaps = false, -- Create extended keymaps.
override_keymaps = false, -- The plugin keymaps will override any existing keymaps.

-- OPTIONS:
always_scroll = false,    -- Scroll the cursor even when the window hasn't scrolled.
centered = true,          -- Keep cursor centered in window when using window scrolling.
disabled = false,         -- Disables the plugin.
default_delay = 7,        -- The default delay (in ms) between each line when scrolling.
hide_cursor = false,      -- Hide the cursor while scrolling. Requires enabling termguicolors!
horizontal_scroll = true, -- Enable smooth horizontal scrolling when view shifts left or right.
max_length = -1,          -- Maximum length (in ms) of a command. The line delay will be
                          -- re-calculated. Setting to -1 will disable this option.
scroll_limit = 150,       -- Max number of lines moved before scrolling is skipped. Setting
                          -- to -1 will disable this option.
```

### Example Configuration

```lua
require('cinnamon').setup {
  extra_keymaps = true,
  override_keymaps = true,
  max_length = 500,
  scroll_limit = -1,
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
Start/end of line:          0, ^ and $
Paragraph movements:        { and }
Prev/next search result:    n, N, *, #, g* and g#
Prev/next cursor location:  <C-O> and <C-I>
Screen scrolling:           zz, zt, zb, z., z<CR>, z-, z^, z+, <C-Y> and <C-E>
Horizontal scrolling:       zH, zL, zs, ze, zh and zl
```

### Extended Keymaps

```
Smooth scrolling for ...

Up/down movements:          [count]j, [count]k, [count]<Up> and [count]<Down>
Left/right movements:       [count]h, [count]l, [count]<Left> and [count]<Right>
```

## ℹ️ API

```lua
Scroll(arg1, arg2, arg3, arg4)
```

* __arg1__ = A string containing the normal mode movement commands. Look at the 'Keymaps' section for examples.
  * To use the go-to-definition LSP function, use 'definition' (or 'declaration'
    for go-to-declaration).
* __arg2__ = Scroll the window with the cursor. (1 for on, 0 for off). Default is 0.
* __arg3__ = Accept a count before the command (1 for on, 0 for off). Default is 0.
* __arg4__ = Length of delay between each line (in ms). Setting to -1 will use the 'default_delay' config value. Default is -1.

_Note: When scrolling horizontally, the delay argument is halved so vertical and horizontal scrolling have similar speeds._

### Keymaps

```lua
-- DEFAULT_KEYMAPS:

-- Half-window movements:
vim.keymap.set({ 'n', 'x' }, '<C-u>', "<Cmd>lua Scroll('<C-u>', 1, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, '<C-d>', "<Cmd>lua Scroll('<C-d>', 1, 1)<CR>")

-- Page movements:
vim.keymap.set({ 'n', 'x' }, '<C-b>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, '<C-f>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, '<PageUp>', "<Cmd>lua Scroll('<C-b>', 1, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, '<PageDown>', "<Cmd>lua Scroll('<C-f>', 1, 1)<CR>")

-- EXTRA_KEYMAPS:

-- Start/end of file and line number movements:
vim.keymap.set({ 'n', 'x' }, 'gg', "<Cmd>lua Scroll('gg')<CR>")
vim.keymap.set({ 'n', 'x' }, 'G', "<Cmd>lua Scroll('G', 0, 1)<CR>")

-- Start/end of line:
vim.keymap.set({ 'n', 'x' }, '0', "<Cmd>lua Scroll('0')<CR>")
vim.keymap.set({ 'n', 'x' }, '^', "<Cmd>lua Scroll('^')<CR>")
vim.keymap.set({ 'n', 'x' }, '$', "<Cmd>lua Scroll('$', 0, 1)<CR>")

-- Paragraph movements:
vim.keymap.set({ 'n', 'x' }, '{', "<Cmd>lua Scroll('{')<CR>")
vim.keymap.set({ 'n', 'x' }, '}', "<Cmd>lua Scroll('}')<CR>")

-- Previous/next search result:
vim.keymap.set('n', 'n', "<Cmd>lua Scroll('n', 1)<CR>")
vim.keymap.set('n', 'N', "<Cmd>lua Scroll('N', 1)<CR>")
vim.keymap.set('n', '*', "<Cmd>lua Scroll('*', 1)<CR>")
vim.keymap.set('n', '#', "<Cmd>lua Scroll('#', 1)<CR>")
vim.keymap.set('n', 'g*', "<Cmd>lua Scroll('g*', 1)<CR>")
vim.keymap.set('n', 'g#', "<Cmd>lua Scroll('g#', 1)<CR>")

-- Previous/next cursor location:
vim.keymap.set('n', '<C-o>', "<Cmd>lua Scroll('<C-o>', 1)<CR>")
vim.keymap.set('n', '<C-i>', "<Cmd>lua Scroll('1<C-i>', 1)<CR>")

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
vim.keymap.set('n', 'zH', "<Cmd>lua Scroll('zH')<CR>")
vim.keymap.set('n', 'zL', "<Cmd>lua Scroll('zL')<CR>")
vim.keymap.set('n', 'zs', "<Cmd>lua Scroll('zs')<CR>")
vim.keymap.set('n', 'ze', "<Cmd>lua Scroll('ze')<CR>")
vim.keymap.set('n', 'zh', "<Cmd>lua Scroll('zh', 0, 1)<CR>")
vim.keymap.set('n', 'zl', "<Cmd>lua Scroll('zl', 0, 1)<CR>")

-- EXTENDED_KEYMAPS:

-- Up/down movements:
vim.keymap.set({ 'n', 'x' }, 'k', "<Cmd>lua Scroll('k', 0, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, 'j', "<Cmd>lua Scroll('j', 0, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, '<Up>', "<Cmd>lua Scroll('k', 0, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, '<Down>', "<Cmd>lua Scroll('j', 0, 1)<CR>")

-- Left/right movements:
vim.keymap.set({ 'n', 'x' }, 'h', "<Cmd>lua Scroll('h', 0, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, 'l', "<Cmd>lua Scroll('l', 0, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, '<Left>', "<Cmd>lua Scroll('h', 0, 1)<CR>")
vim.keymap.set({ 'n', 'x' }, '<Right>', "<Cmd>lua Scroll('l', 0, 1)<CR>")

-- SCROLL_WHEEL_KEYMAPS:

vim.keymap.set({ 'n', 'x' }, '<ScrollWheelUp>', "<Cmd>lua Scroll('<ScrollWheelUp>')<CR>")
vim.keymap.set({ 'n', 'x' }, '<ScrollWheelDown>', "<Cmd>lua Scroll('<ScrollWheelDown>')<CR>")

-- LSP_KEYMAPS:

-- LSP go-to-definition:
vim.keymap.set('n', 'gd', "<Cmd>lua Scroll('definition')<CR>")

-- LSP go-to-declaration:
vim.keymap.set('n', 'gD', "<Cmd>lua Scroll('declaration')<CR>")
```

### Custom Keymaps

Cinnamon will detect when a user has created their own keymaps for a command
and will not replace it.

```lua
-- Activating Cinnamon:
require('cinnamon').setup { extra_keymaps = true }

-- Customizing keymaps that are part of the extra mappings:
vim.keymap.set('n', 'n', "<Cmd>lua Scroll('n')<CR>")
vim.keymap.set('n', 'N', "<Cmd>lua Scroll('N')<CR>")
```
