# Cinnamon Scroll (Neovim)

A scrolling plugin written in lua that works with any movement command.

Is is written in lua, highly customizable, supports using single repeat '.'\
(as it doesn't break or replace your last performed command), and even supports\
scrolling over folds :D.

## Installation

Install with your favorite package manager. No configuration is required to get\
started with the default keymaps.

### Packer

```lua
use 'declancm/cinnamon.nvim'
```

## The Function

```vim
lua Cinnamon.Scroll('arg1', 'arg2', 'arg3', 'arg4', 'arg5', 'arg6')
```

_Note: Each argument is a string separated by a comma.

* arg1 = The movement command (eg. 'gg'). This argument is required as there's\
  no default value.
* arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
* arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
* arg4 = Length of delay between lines (in ms). Default is 5.
* arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.
* arg6 = Max number of lines before scrolling is skipped. Mainly just for big\
  commands such as 'gg' and 'G'. Default is 150.

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
keymap('n', '<C-b>', "<Cmd>lua Cinnamon.Scroll('<C-b>', '1', '1')<CR>", opts)
keymap('n', '<C-f>', "<Cmd>lua Cinnamon.Scroll('<C-f>', '1', '1')<CR>", opts)
keymap('n', '<PageUp>', "<Cmd>lua Cinnamon.Scroll('<C-b>', '1', '1')<CR>", opts)
keymap('n', '<PageDown>', "<Cmd>lua Cinnamon.Scroll('<C-f>', '1', '1')<CR>", opts)

-- Paragraph movements:
keymap('n', '{', "<Cmd>lua Cinnamon.Scroll('{', '0')<CR>", opts)
keymap('n', '}', "<Cmd>lua Cinnamon.Scroll('}', '0')<CR>", opts)
keymap('x', '{', "<Cmd>lua Cinnamon.Scroll('{', '0')<CR>", opts)
keymap('x', '}', "<Cmd>lua Cinnamon.Scroll('}', '0')<CR>", opts)

-- Previous/next search result:
keymap('n', 'n', "<Cmd>lua Cinnamon.Scroll('n', '1', '0', '3')<CR>", opts)
keymap('n', 'N', "<Cmd>lua Cinnamon.Scroll('N', '1', '0', '3')<CR>", opts)
keymap('n', '*', "<Cmd>lua Cinnamon.Scroll('*', '1', '0', '3')<CR>", opts)
keymap('n', '#', "<Cmd>lua Cinnamon.Scroll('#', '1', '0', '3')<CR>", opts)

-- Previous cursor location:
keymap('n', '<C-o>', "<Cmd>lua Cinnamon.Scroll('<C-o>', '1', '0', '3')<CR>", opts)
```

To **disable** the default keymaps, add the following to your .vimrc:

```lua
vim.g.cinnamon_no_defaults = 1
```

## Extra Keymaps

```lua
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- Line number movements:
keymap('n', 'gg', "<Cmd>lua Cinnamon.Scroll('gg', '0', '0', '3')<CR>", opts)
keymap('n', 'G', "<Cmd>lua Cinnamon.Scroll('G', '0', '0', '3')<CR>", opts)
keymap('x', 'gg', "<Cmd>lua Cinnamon.Scroll('gg', '0', '0', '3')<CR>", opts)
keymap('x', 'G', "<Cmd>lua Cinnamon.Scroll('G', '0', '0', '3')<CR>", opts)

-- Up/down movements:
keymap('n', 'k', "<Cmd>lua Cinnamon.Scroll('k', '0', '1', '2', '0')<CR>", opts)
keymap('n', 'j', "<Cmd>lua Cinnamon.Scroll('j', '0', '1', '2', '0')<CR>", opts)
keymap('n', '<Up>', "<Cmd>lua Cinnamon.Scroll('k', '0', '1', '2', '0')<CR>", opts)
keymap('n', '<Down>', "<Cmd>lua Cinnamon.Scroll('j', '0', '1', '2', '0')<CR>", opts)
keymap('x', 'k', "<Cmd>lua Cinnamon.Scroll('k', '0', '1', '2', '0')<CR>", opts)
keymap('x', 'j', "<Cmd>lua Cinnamon.Scroll('j', '0', '1', '2', '0')<CR>", opts)
keymap('x', '<Up>', "<Cmd>lua Cinnamon.Scroll('k', '0', '1', '2', '0')<CR>", opts)
keymap('x', '<Down>', "<Cmd>lua Cinnamon.Scroll('j', '0', '1', '2', '0')<CR>", opts)
```

To **enable** the extra keymaps, add the following to your .vimrc:

```lua
vim.g.cinnamon_extras = 1
```

## Creating Custom Keymaps

Custom keymaps can be created using the 'Cinnamon' command.

```lua
-- Disable default keymaps:
vim.g.cinnamon_no_defaults = 1

-- Scroll half a window without centering the cursor:
keymap('', '<C-u>', "<Cmd>lua Cinnamon.Scroll('<C-u>', '0')<CR>", opts)
keymap('', '<C-d>', "<Cmd>lua Cinnamon.Scroll('<C-d>', '0')<CR>", opts)
keymap('i', '<C-u>', "<Cmd>lua Cinnamon.Scroll('<C-u>', '0')<CR>", opts)
keymap('i', '<C-d>', "<Cmd>lua Cinnamon.Scroll('<C-d>', '0')<CR>", opts)
```
