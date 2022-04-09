local M = {}

local merge = function(...)
  local new_table = {}
  for _, current_table in pairs { ... } do
    for _, item in pairs(current_table) do
      table.insert(new_table, item)
    end
  end
  return new_table
end

-- Up-Down:

M.up_down = { 'j', 'k' }

-- Search:

M.search_repeat = { 'n', 'N' }
M.search_cursor = { '*', '#', 'g*', 'g#' }
M.goto_declaration = { 'gd', 'gD', '1gd', '1gD' }
M.search = merge(M.search_repeat, M.search_cursor, M.goto_declaration)

-- Relative Scroll:

M.relative_scroll_top = { 'zt', 'z<CR>' }
M.relative_scroll_bottom = { 'zb', 'z-' }
M.relative_scroll_caret = { 'z.', 'z<CR>', 'z-' }
M.relative_scroll = merge({ 'zz', 'zt', 'zb' }, M.relative_scroll_caret)

return M
