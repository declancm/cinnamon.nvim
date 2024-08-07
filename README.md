<!-- panvimdoc-ignore-start -->

# Cinnamon Scroll 🍥

[![LuaRocks](https://img.shields.io/luarocks/v/declancm/cinnamon.nvim?logo=lua&color=purple)](https://luarocks.org/modules/declancm/cinnamon.nvim)

Smooth scrolling for __ANY__ command 🤯. A highly
customizable Neovim plugin written in Lua!

<!-- panvimdoc-ignore-end -->

## ✨ Features

* Can add smooth cursor and window scroll animation to any normal mode movement, command, or Lua function
* Horizontal, vertical, and diagonal scrolling
* Adjusts scroll speed based on movement distance
* Non-blocking delays using luv
* Two scrolling modes:
    * `cursor`: animate cursor and window scrolling for any movement
    * `window`: animate window scrolling ONLY when the cursor moves out of view

## 📋 Requirements

* Neovim >= 0.8.0

<!-- panvimdoc-ignore-start -->

## 🎥 Demo

https://github.com/declancm/cinnamon.nvim/assets/90937622/3a107151-a92f-47b9-be26-2afb949c9fe8

<!-- panvimdoc-ignore-end -->

## 📦 Installation

Just install with your favorite package manager and run the setup function.

### Lazy

```lua
{
  "declancm/cinnamon.nvim",
  version = "*", -- use latest release
  opts = {
    -- change default options here
  },
}
```

## ⚙️ Configuration

A settings table can be passed into the setup function for custom options.

### Default Options

```lua
---@class CinnamonOptions
return {
    -- Disable the plugin
    disabled = false,

    keymaps = {
        -- Enable the provided 'basic' keymaps
        basic = false,
        -- Enable the provided 'extra' keymaps
        extra = false,
    },
    
    ---@class ScrollOptions
    options = {
        -- The scrolling mode
        -- `cursor`: animate cursor and window scrolling for any movement
        -- `window`: animate window scrolling ONLY when the cursor moves out of view
        mode = "cursor",

        -- Only animate scrolling if a count is provided
        count_only = false,

        -- Delay between each movement step (in ms)
        delay = 5,

        max_delta = {
            -- Maximum distance for line movements before scroll
            -- animation is skipped. Set to `false` to disable
            line = false,
            -- Maximum distance for column movements before scroll
            -- animation is skipped. Set to `false` to disable
            column = false,
            -- Maximum duration for a movement (in ms). Automatically scales the
            -- delay and step size
            time = 1000,
        },

        step_size = {
            -- Number of cursor/window lines moved per step
            vertical = 1,
            -- Number of cursor/window columns moved per step
            horizontal = 2,
        },

        -- Optional post-movement callback. Not called if the movement is interrupted
        callback = function() end,
    },
}
```

### Example Configuration

```lua
require("cinnamon").setup {
    -- Enable all provided keymaps
    keymaps = {
        basic = true,
        extra = true,
    },
    -- Only scroll the window
    options = { mode = "window" },
}
```

## ⌨️ Keymaps

### Basic Keymaps

**Scroll animation for ...**

| Category | Keys |
|-|-|
| Half-window movements     | `<C-U>` and `<C-D>` |
| Page movements            | `<C-B>`, `<C-F>`, `<PageUp>` and `<PageDown>` |
| Paragraph movements       | `{` and `}` |
| Prev/next search result   | `n`, `N`, `*`, `#`, `g*` and `g#` |
| Prev/next cursor location | `<C-O>` and `<C-I>` |

### Extra Keymaps

**Scroll animation for ...**

| Category | Keys |
|-|-|
| Start/end of file    | `gg` and `G` |
| Line number          | `[count]gg` and `[count]G` |
| Start/end of line    | `0`, `^` and `$` |
| Screen scrolling     | `zz`, `zt`, `zb`, `z.`, `z<CR>`, `z-`, `z^`, `z+`, `<C-Y>` and `<C-E>` |
| Horizontal scrolling | `zH`, `zL`, `zs`, `ze`, `zh` and `zl` |
| Up/down movements    | `[count]j`,  `[count]k`,  `[count]<Up>`,  `[count]<Down>`, `[count]gj`, `[count]gk`, `[count]g<Up>`  and `[count]g<Down>` |
| Left/right movements | `[count]h`,  `[count]l`,  `[count]<Left>` and `[count]<Right>` |

## 🔌 API

### Description

`require("cinnamon").scroll({command}, {options})`

Executes the given command with cursor and window scroll animation.

* `{command}` __(string|function)__ Can be any of the following:
  * Normal mode movement command

    ```lua
    require("cinnamon").scroll("<C-]>")
    ```

  * Command-line (Ex) command when prefixed with a semicolon

    ```lua
    require("cinnamon").scroll(":keepjumps normal! <C-]>")
    ```

  * A Lua function

    ```lua
    require("cinnamon").scroll(function()
        vim.lsp.buf.definition({ loclist = true })
    end)
    ```

* `{options}` __(ScrollOptions?)__ Override the default scroll options.
See the [Default Options](#default-options) for more information.

    ```lua
    require("cinnamon").scroll("<C-]>", { mode = "window" })
    ```

### Examples

```lua
local cinnamon = require("cinnamon")

cinnamon.setup()

-- Centered scrolling:
vim.keymap.set("n", "<C-U>", function() cinnamon.scroll("<C-U>zz") end)
vim.keymap.set("n", "<C-D>", function() cinnamon.scroll("<C-D>zz") end)

-- LSP:
vim.keymap.set("n", "gd", function() cinnamon.scroll(vim.lsp.buf.definition) end)
vim.keymap.set("n", "gD", function() cinnamon.scroll(vim.lsp.buf.declaration) end)

-- Flash.nvim integration:
local flash = require("flash")
local jump = require("flash.jump")

flash.setup({
  action = function(match, state)
    cinnamon.scroll(function()
      jump.jump(match, state)
      jump.on_jump(state)
    end)
  end,
})
```

## 📅 User Events

- `CinnamonCmdPre` - Triggered before the given command is executed
- `CinnamonCmdPost` - Triggered after the given command is executed
- `CinnamonScrollPre` - Triggered before the scroll animation
- `CinnamonScrollPost` - Triggered after the scroll animation

## 🚫 Disabling

- `vim.b.cinnamon_disable` __(boolean)__ Disable scroll animation for the current buffer
- `vim.g.cinnamon_disable` __(boolean)__ Disable scroll animation globally

Example Usage:

```lua
-- Disable scrolling for help buffers
vim.api.nvim_create_autocmd("FileType", {
    pattern = "help",
    callback = function() vim.b.cinnamon_disable = true end,
})
```
