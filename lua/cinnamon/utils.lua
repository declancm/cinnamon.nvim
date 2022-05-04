local utils = {}

utils.error_msg = function(message, code, level)
  code = code or 'Error'
  level = level or 'ERROR'
  vim.notify(string.format('%s: %s', code, message), vim.log.levels[level])
end

utils.create_keymap = function(mode, lhs, rhs)
  if type(mode) == 'table' then
    for _, value in ipairs(mode) do
      if vim.fn.maparg(lhs, value) == '' then
        vim.api.nvim_set_keymap(value, lhs, rhs, { noremap = true })
      end
    end
  else
    if vim.fn.maparg(lhs, mode) == '' then
      vim.api.nvim_set_keymap(mode, lhs, rhs, { noremap = true })
    end
  end
end

utils.contains = function(table, target)
  for _, item in pairs(table) do
    if item == target then
      return true
    end
  end
  return false
end

utils.append = function(...)
  local new_table = {}
  for _, current_table in pairs { ... } do
    for _, item in pairs(current_table) do
      table.insert(new_table, item)
    end
  end
  return new_table
end

utils.merge = function(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == 'table') and (type(t1[k] or false) == 'table') then
      if utils.is_array(t1[k]) then
        t1[k] = utils.concat(t1[k], v)
      else
        utils.merge(t1[k], t2[k])
      end
    else
      t1[k] = v
    end
  end
  return t1
end

utils.concat = function(t1, t2)
  for i = 1, #t2 do
    table.insert(t1, t2[i])
  end
  return t1
end

utils.is_array = function(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then
      return false
    end
  end
  return true
end

return utils
