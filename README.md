<!-- panvimdoc-ignore-start -->

# Cinnamon Scroll 🍥

[![LuaRocks](https://img.shields.io/luarocks/v/declancm/cinnamon.nvim?logo=lua&color=purple)](https://luarocks.org/modules/declancm/cinnamon.nvim)

Smooth scrolling for __ANY__ command 🤯. A highly
customizable Neovim plugin written in Lua!

<!-- panvimdoc-ignore-end -->

## ✨ Features

* Can add smooth scrolling to any normal mode movement, command, or Lua function
* Horizontal, vertical, and diagonal scrolling
* Adjusts scroll speed based on movement distance
* Non-blocking delays using luv
* Two scrolling modes:
    * `cursor`: Smoothly scrolls the cursor for any movement
    * `window`: Smoothly scrolls the window ONLY when the cursor moves out of view

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
        -- Optional post-movement callback
        callback = function() end,
        -- Delay between each movement step (in ms)
        delay = 5,
        step_size = {
            -- Default number of cursor/window lines moved per step
            vertical = 1,
            -- Default number of cursor/window columns moved per step
            horizontal = 2,
        },
        max_delta = {
            -- Maximum distance for line movements before smooth
            -- scrolling is skipped. Set to `false` to disable
            line = false,
            -- Maximum distance for column movements before smooth
            -- scrolling is skipped. Set to `false` to disable
            column = false,
            -- Maximum duration for a movement (in ms). Automatically scales the delay and step size
            time = 1000,
        },
        -- The scrolling mode
        -- `cursor`: Smoothly scrolls the cursor for any movement
        -- `window`: Smoothly scrolls the window ONLY when the cursor moves out of view
        mode = "cursor",
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

**Smooth scrolling for ...**

| Category | Keys |
|-|-|
| Half-window movements     | `<C-U>` and `<C-D>` |
| Page movements            | `<C-B>`, `<C-F>`, `<PageUp>` and `<PageDown>` |
| Paragraph movements       | `{` and `}` |
| Prev/next search result   | `n`, `N`, `*`, `#`, `g*` and `g#` |
| Prev/next cursor location | `<C-O>` and `<C-I>` |

### Extra Keymaps

**Smooth scrolling for ...**

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

-- Setup the plugin with default options
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
- `CinnamonScrollPre` - Triggered before the smooth scroll movement
- `CinnamonScrollPost` - Triggered after the smooth scroll movement
