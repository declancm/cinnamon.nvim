# Cinnamon Scroll (Neovim) 🌀

A scrolling plugin written in lua that works with any 👏 movement 👏 command 👏.

Is is written in lua, highly customizable, supports single repeat '.' (as it
doesn't break or replace your last performed command), and supports scrolling
over folds :D.

_Petition for a cinnamon roll emoji:_ <https://www.change.org/p/apple-cinnamon-roll-emoji>

## Installation

Install with your favorite package manager. No configuration is required to get
started with the default keymaps.

### Packer

```lua
use 'declancm/cinnamon.nvim'
```

## The Function

```lua
Cinnamon.Scroll('arg1', 'arg2', 'arg3', 'arg4', 'arg5')
```

* arg1 = The movement command (eg. 'gg'). This argument is required as there's
  no default value.
* arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
* arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
* arg4 = Length of delay between lines (in ms). Default is 5.
* arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

_Note: arg1 is a string while the others are integers._

## Configuration

A settings table can be passed into the setup function for custom options.

The default settings are:

```lua
require('cinnamon').setup {
  -- Enable default keymaps:
  default_keymaps = true,
  -- Enable extra keymaps:
  extra_keymaps = false,
  -- Enable extended keymaps:
  extended_keymaps = false,
  -- Keep cursor centered in window when using window scrolling (arg2):
  centered = true,
  -- Disable the plugin:
  disable = false,
  -- Max number of lines moved before scrolling is skipped (mainly for big commands such as 'gg' and 'G'):
  scroll_limit = 150,
}
```

There is no need to call `require('cinnamon').setup()` if you do not wish to set
custom settings.

## Default Keymaps

```lua
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

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
```

## Extra Keymaps

```lua
-- Line number movements:
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

keymap('n', 'gg', "<Cmd>lua Cinnamon.Scroll('gg', 0, 0, 3)<CR>", opts)
keymap('n', 'G', "<Cmd>lua Cinnamon.Scroll('G', 0, 1, 3)<CR>", opts)
keymap('x', 'gg', "<Cmd>lua Cinnamon.Scroll('gg', 0, 0, 3)<CR>", opts)
keymap('x', 'G', "<Cmd>lua Cinnamon.Scroll('G', 0, 1, 3)<CR>", opts)

-- Paragraph movements:
keymap('n', '{', "<Cmd>lua Cinnamon.Scroll('{', 0)<dCR>", opts)
keymap('n', '}', "<Cmd>lua Cinnamon.Scroll('}', 0)<CR>", opts)
keymap('x', '{', "<Cmd>lua Cinnamon.Scroll('{', 0)<CR>", opts)
keymap('x', '}', "<Cmd>lua Cinnamon.Scroll('}', 0)<CR>", opts)

-- Previous/next search result:
keymap('n', 'n', "<Cmd>lua Cinnamon.Scroll('n', 1, 0, 3)<CR>", opts)
keymap('n', 'N', "<Cmd>lua Cinnamon.Scroll('N', 1, 0, 3)<CR>", opts)
keymap('n', '*', "<Cmd>lua Cinnamon.Scroll('*', 1, 0, 3)<CR>", opts)
keymap('n', '#', "<Cmd>lua Cinnamon.Scroll('#', 1, 0, 3)<CR>", opts)
keymap('n', 'g*', "<Cmd>lua Cinnamon.Scroll('g*', 1, 0, 3)<CR>", opts)
keymap('n', 'g#', "<Cmd>lua Cinnamon.Scroll('g#', 1, 0, 3)<CR>", opts)

-- Previous/next cursor location:
keymap('n', '<C-o>', "<Cmd>lua Cinnamon.Scroll('<C-o>', 1, 0, 3)<CR>", opts)
keymap('n', '<C-i>', "<Cmd>lua Cinnamon.Scroll('1<C-i>', 1, 0, 3)<CR>", opts)
```

_Note: `1<C-i>` has to be used instead of `<C-i>` to prevent it from being
expanded into a literal tab, as `<Tab>` and `<C-i>` are equivalent for vim._

## Extended Keymaps

```lua
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- Up/down movements:
keymap('n', 'k', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 2, 0)<CR>", opts)
keymap('n', 'j', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 2, 0)<CR>", opts)
keymap('x', 'k', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 2, 0)<CR>", opts)
keymap('x', 'j', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 2, 0)<CR>", opts)
keymap('n', '<Up>', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 2, 0)<CR>", opts)
keymap('n', '<Down>', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 2, 0)<CR>", opts)
keymap('x', '<Up>', "<Cmd>lua Cinnamon.Scroll('k', 0, 1, 2, 0)<CR>", opts)
keymap('x', '<Down>', "<Cmd>lua Cinnamon.Scroll('j', 0, 1, 2, 0)<CR>", opts)
```
## Custom Keymaps

If creating a custom keymap which is within 'default keymaps' or 'extra 
keymaps', make sure they are disabled so yours isn't overridden.

Example:

```lua
require('cinnamon').setup { default_keymaps = false }

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

keymap('', '<C-u>', "<Cmd>lua Cinnamon.Scroll('<C-u>')<CR>", opts)
keymap('', '<C-d>', "<Cmd>lua Cinnamon.Scroll('<C-d>')<CR>", opts)
```
