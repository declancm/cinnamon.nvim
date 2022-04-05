local S = {}

local options = require('cinnamon').options
local U = require('cinnamon.utils')
local F = require('cinnamon.functions')

-- TODO: get the scroll to work for g commands such as gj and gk.

--[[

require('cinnamon.scroll').Scroll('arg1', 'arg2', 'arg3', 'arg4', 'arg5', 'arg6')

arg1 = The movement command (eg. 'ggVG' to highlight the file). This argument
       is required as there's no default value.
arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
arg4 = Length of delay between lines (in ms). Default is 5.
arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

Note: Each argument is a string separated by a comma.

]]

function S.Scroll(command, scrollWin, useCount, delay, slowdown)
  if options.disable then
    U.ErrorMsg('Cinnamon is disabled')
    return
  end

  -- Check if command argument exists.
  if not command then
    U.ErrorMsg('The command argument cannot be nil')
    return
  end

  -- Execute command if only moving one line.
  for _, item in pairs { 'j', 'k' } do
    if item == command and vim.v.count == 0 then
      vim.cmd('norm! ' .. command)
      return
    end
  end

  -- Setting argument defaults:
  scrollWin = scrollWin or 1
  useCount = useCount or 0
  delay = delay or 5
  slowdown = slowdown or 1

  -- Save options.
  local saved = {}
  saved.lazyredraw = vim.opt.lazyredraw:get()

  -- Set options.
  vim.opt.lazyredraw = false

  -- Check for any errors with the command.
  if F.CheckMovementErrors(command) == true then
    return
  end

  -- Get the scroll distance and the column position.
  local distance, newColumn, fileChanged, limitExceeded = F.GetScrollDistance(command, useCount)
  if fileChanged then
    return
  elseif limitExceeded then
    if scrollWin == 1 and options.centered then
      vim.cmd('norm! zz')
    end
    return
  end

  -- Perform the scroll.
  if distance > 0 then
    F.ScrollDown(distance, scrollWin, delay, slowdown)
  elseif distance < 0 then
    F.ScrollUp(distance, scrollWin, delay, slowdown)
  end

  -- Change the cursor column position if required.
  if newColumn ~= -1 then
    vim.fn.cursor(vim.fn.line('.'), newColumn)
  end

  -- Restore options.
  vim.opt.lazyredraw = saved.lazyredraw
end

return S
