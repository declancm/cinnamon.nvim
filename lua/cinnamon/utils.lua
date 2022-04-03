local U = {}

function U.ErrorMsg(message, code, color)
  message = vim.fn.escape(message, '"\\')
  code = code or 'Error'
  color = color or 'ErrorMsg'
  vim.cmd(string.format('echohl %s | echom "%s: %s" | echohl None', color, code, message))
end

return U
