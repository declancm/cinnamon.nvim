# Cinnamon Scroll 🌀

Smooth scrolling for __ANY__ movement command 🤯. A highly customizable Neovim
plugin written in Lua which doesn't break the single-repeat "." command (unlike
some other plugins) and supports scrolling over folds.

__Now supports the go-to-definition and go-to-declaration builtin LSP functions 🥳🎉.__

```lua
-- LSP go-to-definition.
keymap('n', 'gd', "<Cmd>lua Scroll('definition')<CR>", opts)
-- LSP go-to-declaration.
keymap('n', 'gD', "<Cmd>lua Scroll('declaration')<CR>", opts)
```

_Petition for a cinnamon roll emoji:_ <https://www.change.org/p/apple-cinnamon-roll-emoji>

## 📦 Installation

Install with your favorite package manager. No configuration is required to get
started with the default keymaps. I highly recommend trying the extra keymaps as
the are what set this plugin apart.

### Packer

```lua
use 'declancm/cinnamon.nvim'
```

## ⚙️ Configuration

A settings table can be passed into the setup function for custom options.

__Default Settings:__

```lua
require('cinnamon').setup {
  default_keymaps = true,   -- Enable default keymaps.
  extra_keymaps = false,    -- Enable extra keymaps.
  extended_keymaps = false, -- Enable extended keymaps.
  centered = true,    -- Keep cursor centered in window when using window scrolling.
  disable = false,    -- Disable the plugin.
  scroll_limit = 150, -- Max number of lines moved before scrolling is skipped.
}
```

__Default Keymaps:__

```
Smooth scrolling for ...

Half-window movements:      <C-U> and <C-D>
Page movements:             <C-B>, <C-F>, <PageUp> and <PageDown>
```

__Extra Keymaps:__

```
Smooth scrolling for ...

Start/end of file:          gg and G
Line number:                [count]G
Paragraph movements:        { and }
Prev/next search result:    n, N, *, #, g* and g#
Prev/next cursor location:  <C-O> and <C-I>
Window scrolling:           zz, z., zt, zb, z+ and z^
```

__Extended Keymaps:__

```
Smooth scrolling for ...

Up/down movements:          [count]j, [count]k, [count]<Up> and [count]<Down>
```

## ℹ️ API

```lua
Scroll(arg1, arg2, arg3, arg4, arg5)
```

* __arg1__ = A string containing the normal mode movement command.
  * To use the go-to-definition LSP function, use 'definition' (or 'declaration'
    for go-to-declaration).
* __arg2__ = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
* __arg3__ = Accept a count before the command (1 for on, 0 for off). Default is 0.
* __arg4__ = Length of delay between lines (in ms). Default is 5.
* __arg5__ = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

_Note: arg1 is a string while the others are integers._

## ⌨️ Keymaps

### Default Keymaps

```lua
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

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
```

### Extra Keymaps

```lua
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- Start/end of file and line number movements:
keymap('n', 'gg', "<Cmd>lua Scroll('gg', 0, 0, 3)<CR>", opts)
keymap('x', 'gg', "<Cmd>lua Scroll('gg', 0, 0, 3)<CR>", opts)
keymap('n', 'G', "<Cmd>lua Scroll('G', 0, 1, 3)<CR>", opts)
keymap('x', 'G', "<Cmd>lua Scroll('G', 0, 1, 3)<CR>", opts)

-- Paragraph movements:
keymap('n', '{', "<Cmd>lua Scroll('{', 0)<dCR>", opts)
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
keymap('n', 'z.', "<Cmd>lua Scroll('z.', 0, 1)<CR>", opts)
keymap('n', 'zt', "<Cmd>lua Scroll('zt', 0, 1)<CR>", opts)
keymap('n', 'zb', "<Cmd>lua Scroll('zb', 0, 1)<CR>", opts)
keymap('n', 'z^', "<Cmd>lua Scroll('z^', 0, 1)<CR>", opts)
keymap('n', 'z+', "<Cmd>lua Scroll('z+', 0, 1)<CR>", opts)
```

_Note: `1<C-i>` has to be used instead of `<C-i>` to prevent it from being
expanded into a literal tab, as `<Tab>` and `<C-i>` are equivalent for vim._

### Extended Keymaps

```lua
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- Up/down movements:
keymap('n', 'k', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>", opts)
keymap('x', 'k', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>", opts)
keymap('n', 'j', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>", opts)
keymap('x', 'j', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>", opts)
keymap('n', '<Up>', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>", opts)
keymap('x', '<Up>', "<Cmd>lua Scroll('k', 0, 1, 3, 0)<CR>", opts)
keymap('n', '<Down>', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>", opts)
keymap('x', '<Down>', "<Cmd>lua Scroll('j', 0, 1, 3, 0)<CR>", opts)
```
### Custom Keymaps

If creating a custom keymap which is within the preset keymaps, make sure they 
are disabled so yours isn't overridden.

```lua
-- Disabling the default keymaps.
require('cinnamon').setup { default_keymaps = false }

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- Customizing keymaps that are part of the default mappings.
keymap('', '<C-u>', "<Cmd>lua Scroll('<C-u>', 1, 0, 3)<CR>", opts)
keymap('', '<C-d>', "<Cmd>lua Scroll('<C-d>', 1, 0, 3)<CR>", opts)
```
