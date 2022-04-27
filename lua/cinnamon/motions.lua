local M = {}

local utils = require('cinnamon.utils')

-- Up-Down:

M.up_down = { 'j', 'k' }

-- Left-Right:

M.left_right = { 'h', 'l' }

-- Search:

M.search_repeat = { 'n', 'N' }
M.search_cursor = { '*', '#', 'g*', 'g#' }
M.goto_declaration = { 'gd', 'gD', '1gd', '1gD' }
M.search = utils.append(M.search_repeat, M.search_cursor, M.goto_declaration)

-- Screen Scrolling:

M.scroll_count = { '<C-y>', '<C-e>' }
M.horizontal_scroll_count = { 'zh', 'zl' }

-- No Scroll Movements:

M.no_scroll = utils.append(M.up_down, M.left_right, M.scroll_count, M.horizontal_scroll_count)

return M
