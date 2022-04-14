if vim.g.__cinnamon_setup_loaded then
  return
end

local cinnamon_status, cinnamon = pcall(require, 'cinnamon')
if not cinnamon_status then
  print('Error: cinnamon setup failed')
  return
end

cinnamon.setup()
