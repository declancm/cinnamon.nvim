local M = {}

local utils = require('cinnamon.utils')

-- TODO: get the scroll to work for g commands such as gj and gk.

--[[

require('cinnamon.scroll').Scroll('arg1', 'arg2', 'arg3', 'arg4', 'arg5', 'arg6')

arg1 = The movement command (eg. 'gg'). This argument is required as there's\
no default value.
arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
arg4 = Length of delay between lines (in ms). Default is 5.
arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

Note: Each argument is a string separated by a comma.

]]

function M.Scroll(command, scrollWin, useCount, delay, slowdown)
  if vim.g.__cinnamon_disabled then
    print('Cinnamon is disabled.')
    return
  end
  -- Check if command argument exists.
  if not command then
    vim.cmd([[echohl ErrorMsg | echo "Cinnamon: The command argument cannot be nil." | echohl None]])
    return
  end
  -- Setting defaults:
  scrollWin = scrollWin or 1
  useCount = useCount or 0
  delay = delay or 5
  slowdown = slowdown or 1
  -- Execute command if just moving one line.
  for _, item in pairs { 'j', 'k' } do
    if item == command and vim.v.count1 == 1 then
      vim.cmd('norm! ' .. command)
      return
    end
  end
  -- Check for any errors with the command.
  if utils.CheckMovementErrors(command) == true then
    return
  end
  -- Get the scroll distance and the column position.
  local distance, newColumn, fileChanged, limitExceeded = utils.GetScrollDistance(command, useCount)
  if fileChanged then
    return
  elseif limitExceeded then
    if scrollWin == 1 and vim.g.__cinnamon_centered == true then
      vim.cmd('norm! zz')
    end
    return
  end
  -- Perform the scroll.
  if distance > 0 then
    utils.ScrollDown(distance, scrollWin, delay, slowdown)
  elseif distance < 0 then
    utils.ScrollUp(distance, scrollWin, delay, slowdown)
  end
  -- Change the cursor column position if required.
  if newColumn ~= -1 then
    vim.fn.cursor(vim.fn.line('.'), newColumn)
  end
end

return M
