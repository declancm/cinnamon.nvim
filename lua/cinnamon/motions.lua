local M = {}

local utils = require('cinnamon.utils')

local function t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- Vertical:

M.vertical = { 'j', 'k' }
M.window_vertical = { t('<C-y>'), t('<C-e>') }

-- Horizontal:

M.horizontal = { 'h', 'l' }
M.view_horizontal = { 'zh', 'zl' }

-- Mouse Wheel:

M.mouse_wheel = { t('<ScrollWheelUp>'), t('<ScrollWheelDown>') }

-- Search:

M.search_repeat = { 'n', 'N' }
M.search_cursor = { '*', '#', 'g*', 'g#' }
M.goto_declaration = { 'gd', 'gD', '1gd', '1gD' }
M.search = utils.append(M.search_repeat, M.search_cursor, M.goto_declaration)

-- No Scroll Movements:

M.no_scroll = utils.append(M.vertical, M.horizontal, M.window_vertical, M.view_horizontal)

return M
