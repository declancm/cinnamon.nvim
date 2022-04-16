local M = {}

local utils = require('cinnamon.utils')

-- Up-Down:

M.up_down = { 'j', 'k' }

-- Search:

M.search_repeat = { 'n', 'N' }
M.search_cursor = { '*', '#', 'g*', 'g#' }
M.goto_declaration = { 'gd', 'gD', '1gd', '1gD' }
M.search = utils.append(M.search_repeat, M.search_cursor, M.goto_declaration)

-- Window Scrolling:

M.scroll_count = { '<C-y>', '<C-e>' }

-- Single-Line Movements:

M.single_line = utils.append(M.up_down, M.scroll_count)

return M
