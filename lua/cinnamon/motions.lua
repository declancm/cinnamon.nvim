local M = {}

local utils = require('cinnamon.utils')

-- Up-Down:

M.up_down = { 'j', 'k' }

-- Search:

M.search_repeat = { 'n', 'N' }
M.search_cursor = { '*', '#', 'g*', 'g#' }
M.goto_declaration = { 'gd', 'gD', '1gd', '1gD' }
M.search = utils.append(M.search_repeat, M.search_cursor, M.goto_declaration)

-- Relative Scroll (no cursor movement):

M.relative_scroll_top = { 'zt', 'z<CR>', 'zt^' }
M.relative_scroll_center = { 'zz', 'z.', 'zz^' }
M.relative_scroll_bottom = { 'zb', 'z-', 'zb^' }
M.relative_scroll = utils.append(M.relative_scroll_top, M.relative_scroll_center, M.relative_scroll_bottom)

-- Window Scroll:

M.window_scroll_top = utils.append(M.relative_scroll_top, { 'z+' })
M.window_scroll_bottom = utils.append(M.relative_scroll_bottom, { 'z^' })
M.window_scroll = utils.append(M.window_scroll_top, M.relative_scroll_center, M.window_scroll_bottom)

return M
