if vim.g.__cinnamon_setup_loaded then
  return
end

local status, cinnamon = pcall(require, 'cinnamon')
if not status then
  print('Error: cinnamon setup failed')
  return
end

cinnamon.setup()
