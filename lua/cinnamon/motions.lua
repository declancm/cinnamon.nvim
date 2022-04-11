local M = {}

local utils = require('cinnamon.utils')

-- Up-Down:

M.up_down = { 'j', 'k' }

-- Search:

M.search_repeat = { 'n', 'N' }
M.search_cursor = { '*', '#', 'g*', 'g#' }
M.goto_declaration = { 'gd', 'gD', '1gd', '1gD' }
M.search = utils.add(M.search_repeat, M.search_cursor, M.goto_declaration)

-- Relative Scroll (no cursor movement):

M.relative_scroll_top = { 'zt', 'z<CR>' }
M.relative_scroll_center = { 'zz', 'z.' }
M.relative_scroll_bottom = { 'zb', 'z-' }
M.relative_scroll_caret = { 'z.', 'z<CR>', 'z-' }
M.relative_scroll = utils.add(M.relative_scroll_top, M.relative_scroll_center, M.relative_scroll_bottom)

-- Window Scroll:

M.window_scroll_top = utils.add(M.relative_scroll_top, { 'z+' })
M.window_scroll_bottom = utils.add(M.relative_scroll_bottom, { 'z^' })
M.window_scroll = utils.add(M.window_scroll_top, M.relative_scroll_center, M.window_scroll_bottom)

return M
