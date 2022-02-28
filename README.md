# cinnamon-scroll

A scrolling plugin for neovim that works with any vertical movement command.

Is is written in lua, highly customizable, supports using '.' (single repeat)\
as it doesn't break or replace your last performed command, and even supports\
scrolling over folds.

Fun bonus: supports tpope's vim-repeat if that's your jam.

## Installation

Install with your favorite package manager. No configuration is required to get\
started with the default keymaps.

Install 'tpope/vim-repeat' to use the '.' command to repeat scroll movements.\
Totally optional though :D.

### Packer

```lua
use 'declancm/cinnamon.nvim'

-- To have the repeat feature:
use {
  'declancm/cinnamon.nvim',
  requires = 'tpope/vim-repeat',
}
```

## The Command

```vim
<Cmd>Cinnamon arg1 arg2 arg3 arg4 arg5 arg6 <CR>
```

_Note: A whitespace is used to separate the arguments._

* arg1 = The movement command (eg. 'gg'). This argument is required as there's\
  no default value.
* arg2 = Keep cursor centered in the window. (1 for on, 0 for off). Default is 1.
* arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
* arg4 = Length of delay between lines (in ms). Default is 5.
* arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.
* arg6 = Max number of lines before scrolling is skipped. Mainly just for big\
  commands such as 'gg' and 'G'. Default is 300.

## Default Keymaps

```lua
local opts = { noremap = true, silent = true }
local set_keymap = vim.api.nvim_set_keymap

-- Paragraph movements.
set_keymap('n', '{', '<Cmd>Cinnamon { 0 <CR>', opts)
set_keymap('n', '}', '<Cmd>Cinnamon } 0 <CR>', opts)
set_keymap('x', '{', '<Cmd>Cinnamon { 0 <CR>', opts)
set_keymap('x', '}', '<Cmd>Cinnamon } 0 <CR>', opts)

-- Half-window movements.
set_keymap('', '<C-u>', '<Cmd>Cinnamon <C-u> <CR>', opts)
set_keymap('', '<C-d>', '<Cmd>Cinnamon <C-d> <CR>', opts)
set_keymap('i', '<C-u>', '<Cmd>Cinnamon <C-u> <CR>', opts)
set_keymap('i', '<C-d>', '<Cmd>Cinnamon <C-d> <CR>', opts)

-- Page movements.
set_keymap('n', '<C-b>', '<Cmd>Cinnamon <C-b> 1 1 <CR>', opts)
set_keymap('n', '<C-f>', '<Cmd>Cinnamon <C-f> 1 1 <CR>', opts)
set_keymap('n', '<PageUp>', '<Cmd>Cinnamon <C-b> 1 1 <CR>', opts)
set_keymap('n', '<PageDown>', '<Cmd>Cinnamon <C-f> 1 1 <CR>', opts)
```

To **disable** the default keymaps, add the following to your .vimrc:

```lua
vim.g.cinnamon_no_defaults = 1
```

## Extra Keymaps

```lua
local opts = { noremap = true, silent = true }
local set_keymap = vim.api.nvim_set_keymap

-- Start and end of file movements.
set_keymap('n', 'gg', '<Cmd>Cinnamon gg 0 0 3 <CR>', opts)
set_keymap('n', 'G', '<Cmd>Cinnamon G 0 0 3 <CR>', opts)
set_keymap('x', 'gg', '<Cmd>Cinnamon gg 0 0 3 <CR>', opts)
set_keymap('x', 'G', '<Cmd>Cinnamon G 0 0 3 <CR>', opts)

-- Previous/next cursor position.
set_keymap('n', '<C-o>', '<Cmd>Cinnamon <C-o> 0 0 3 <CR>', opts)
set_keymap('n', '<C-i>', '<Cmd>Cinnamon <C-i> 0 0 3 <CR>', opts)

-- Up and down movements which accepts a count (eg. 69j to scroll down 69 lines).
set_keymap('n', 'k', '<Cmd>Cinnamon k 0 1 2 0 <CR>', opts)
set_keymap('n', 'j', '<Cmd>Cinnamon j 0 1 2 0 <CR>', opts)
set_keymap('n', '<Up>', '<Cmd>Cinnamon k 0 1 2 0 <CR>', opts)
set_keymap('n', '<Down>', '<Cmd>Cinnamon j 0 1 2 0 <CR>', opts)
set_keymap('x', 'k', '<Cmd>Cinnamon k 0 1 2 0 <CR>', opts)
set_keymap('x', 'j', '<Cmd>Cinnamon j 0 1 2 0 <CR>', opts)
set_keymap('x', '<Up>', '<Cmd>Cinnamon k 0 1 2 0 <CR>', opts)
set_keymap('x', '<Down>', '<Cmd>Cinnamon j 0 1 2 0 <CR>', opts)
```

To **enable** the extra keymaps, add the following to your .vimrc:

```lua
vim.g.cinnamon_extras = 1
```

## Creating Custom Keymaps

Custom keymaps can be created using the 'Cinnamon' command.

```lua
-- Disable default keymaps
vim.g.cinnamon_no_defaults = 1
-- Jump to first/last line of paragraph intead of the whitespace
set_keymap('x', '{', 'k<Cmd>Cinnamon {j 0 <CR>', opts)
set_keymap('x', '}', 'j<Cmd>Cinnamon }k 0 <CR>', opts)
```

The first argument for the '{' keymap will perform a movement of '{j' which will\
jump to the first whitespace line and then move one line down. The next argument\
disables the window scrolling as the default is on.
