# Cinnamon Scroll 🍥

Smooth scrolling for __ANY__ movement command 🤯. A
highly customizable Neovim plugin written in Lua!

__Features:__
* Can add smooth scrolling to any normal mode movement, command, or Lua function.
* Optional custom callbacks per movement.
* Horizontal, vertical, and diagonal scrolling.
* Non-blocking delays using luv.
* Scroll over folds.
* Scroll over wrapped lines.

__Petition for a cinnamon roll emoji:__<https://www.change.org/p/apple-cinnamon-roll-emoji>

## 📦 Installation

Just install with your favorite package manager and run the setup function to get the basic keymaps or to adjust the settings.

### Packer

```lua
use {
  'declancm/cinnamon.nvim',
  config = function() require('cinnamon').setup() end
}
```

### Lazy

```lua
{
  'declancm/cinnamon.nvim',
  config = true
}
```

## ⚙️ Configuration

A settings table can be passed into the setup function for custom options.

### Default Settings

```lua
return {
    disabled = false,           -- Disable the plugin
    keymaps = {
        basic = true,           -- Enable the basic keymaps
        extra = false,          -- Enable the extra keymaps
    },
    options = {
        callback = function()   -- Post-movement callback
        end,
        delay = 5,              -- Delay between each movement step (in ms)
        max_delta = {
            line = 150,         -- Maximum delta for line movements
            column = 200,       -- Maximum delta for column movements
        },
    },
}
```

### Example Configuration

```lua
require('cinnamon').setup {
    keymaps = { extra = true }, -- Enable the 'extra' keymaps
}
```

## ⌨️ Keymaps

### Basic Keymaps

**Smooth scrolling for ...**

| Movement Type | Keys |
|-|-|
| Half-window movements     | `<C-U>` and `<C-D>` |
| Page movements            | `<C-B>`, `<C-F>`, `<PageUp>` and `<PageDown>` |
| Paragraph movements       | `{` and `}` |
| Prev/next search result   | `n`, `N`, `*`, `#`, `g*` and `g#` |
| Prev/next cursor location | `<C-O>` and `<C-I>` |

### Extra Keymaps

**Smooth scrolling for ...**

| Movement Type | Keys |
|-|-|
| Start/end of file    | `gg` and `G` |
| Line number          | `[count]gg` and `[count]G` |
| Start/end of line    | `0`, `^` and `$` |
| Screen scrolling     | `zz`, `zt`, `zb`, `z.`, `z<CR>`, `z-`, `z^`, `z+`, `<C-Y>` and `<C-E>` |
| Horizontal scrolling | `zH`, `zL`, `zs`, `ze`, `zh` and `zl` |
| Up/down movements    | `[count]j`,  `[count]k`,  `[count]<Up>`,  `[count]<Down>`, `[count]gj`, `[count]gk`, `[count]g<Up>`  and `[count]g<Down>` |
| Left/right movements | `[count]h`,  `[count]l`,  `[count]<Left>` and `[count]<Right>` |

## ℹ️ API

```lua
require('cinnamon').scroll(command, options)
```

* __command__ = Can be any of the following:
  * Normal mode movement command

    ```lua
    require('cinnamon').scroll("<C-]>")
    ```

  * Command-line (Ex) command when prefixed with a semicolon

    ```lua
    require('cinnamon').scroll(":keepjumps normal! <C-]>")
    ```

  * A Lua function

    ```lua
    require('cinnamon').scroll(function()
        vim.lsp.buf.definition({ loclist = true })
    end)
    -- OR
    require('cinnamon').scroll(vim.lsp.buf.definition)
    ```

* __options__ = An optional table to overwrite options from the configuration table.

    ```lua
    require('cinnamon').scroll("<C-]>", { delay = 3 })
    ```

### Example Keymaps

```lua
local scroll = require('cinnamon').scroll

-- Centered scrolling:
vim.keymap.set('n', '<C-U>', scroll('<C-U>zz'))
vim.keymap.set('n', '<C-D>', scroll('<C-D>zz'))

-- LSP:
vim.keymap.set('n', 'gd', scroll(vim.lsp.buf.definition))
vim.keymap.set('n', 'gD', scroll(vim.lsp.buf.declaration))
```
