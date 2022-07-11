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

-- Vertical:

M.vertical = { 'j', 'k' }
M.window_vertical = { t('<C-y>'), t('<C-e>') }

-- Horizontal:

M.horizontal = { 'h', 'l' }
M.view_horizontal = { 'zh', 'zl' }

-- Scroll wheel:

M.scroll_wheel = { t('<ScrollWheelUp>'), t('<ScrollWheelDown>') }

-- Search:

M.search_repeat = { 'n', 'N' }
M.search_cursor = { '*', '#', 'g*', 'g#' }
M.goto_declaration = { 'gd', 'gD', '1gd', '1gD' }
M.search = append_table(M.search_repeat, M.search_cursor, M.goto_declaration)

-- Single line/char movements:

M.no_scroll = append_table(M.vertical, M.horizontal, M.window_vertical, M.view_horizontal)

return M
