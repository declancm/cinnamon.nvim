local U = {}

function U.ErrorMsg(message, code, color)
  message = vim.fn.escape(message, '"\\')
  code = code or "Error"
  color = color or "ErrorMsg"
  vim.cmd(string.format('echohl %s | echom "%s: %s" | echohl None', color, code, message))
end

function U.merge(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == "table") and (type(t1[k] or false) == "table") then
      if U.is_array(t1[k]) then
        t1[k] = U.concat(t1[k], v)
      else
        U.merge(t1[k], t2[k])
      end
    else
      t1[k] = v
    end
  end
  return t1
end

function U.concat(t1, t2)
  for i = 1, #t2 do
    table.insert(t1, t2[i])
  end
  return t1
end

function U.is_array(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then
      return false
    end
  end
  return true
end

return U
