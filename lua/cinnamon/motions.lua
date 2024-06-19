local M = {}

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local append_table = function(...)
  local new_table = {}
  for _, current_table in pairs { ... } do
    for _, item in pairs(current_table) do
      table.insert(new_table, item)
    end
  end
  return new_table
end

-- Scroll wheel:

M.scroll_wheel = { t('<ScrollWheelUp>'), t('<ScrollWheelDown>') }

-- Search:

M.search_repeat = { 'n', 'N' }
M.search_cursor = { '*', '#', 'g*', 'g#' }
M.goto_declaration = { 'gd', 'gD', '1gd', '1gD' }
M.search = append_table(M.search_repeat, M.search_cursor, M.goto_declaration)

-- Movements that never require a smooth scroll (without using a count):

M.no_scroll_vertical =
  { 'j', 'k', 'gj', 'gk', t('<Up>'), t('<Down>'), t('g<Up>'), t('g<Down>'), t('<C-y>'), t('<C-e>') }
M.no_scroll_horizontal = { 'h', 'l', t('<Left>'), t('<Right>'), 'zh', 'zl' }
M.no_scroll = append_table(M.no_scroll_vertical, M.no_scroll_horizontal)

return M
