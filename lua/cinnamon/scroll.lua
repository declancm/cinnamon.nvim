local S = {}

local config = require('cinnamon.config')
local U = require('cinnamon.utils')
local F = require('cinnamon.functions')

-- TODO: add doc files.

--[[

require('cinnamon.scroll').Scroll(arg1, arg2, arg3, arg4, arg5, arg6)

arg1 = A string containing the normal mode movement command.
  * To use the go-to-definition LSP function, use 'definition' (or 'declaration'
    for go-to-declaration).
arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
arg4 = Length of delay between lines (in ms). Default is 5.
arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

Note: arg1 is a string while the others are integers.

]]

function S.Scroll(command, scrollWin, useCount, delay, slowdown)
  if config.disable then
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
    if item == command and vim.v.count1 == 1 then
      vim.cmd('norm! ' .. command)
      return
    end
  end

  -- Setting argument defaults:
  scrollWin = scrollWin or 1
  useCount = useCount or 0
  delay = delay or 5
  slowdown = slowdown or 1

  -- Execute command if using a scroll cursor command with a count.
  for _, item in pairs { 'zz', 'z.', 'zt', 'z<CR>', 'zb', 'z-' } do
    if item == command and useCount and vim.v.count > 0 then
      vim.cmd('norm! ' .. vim.v.count .. command)
      return
    end
  end

  -- Save options.
  local saved = {}
  saved.lazyredraw = vim.opt.lazyredraw:get()

  -- Set options.
  vim.opt.lazyredraw = false

  -- Check for any errors with the command.
  if F.CheckCommandErrors(command) then
    return
  end

  -- Get the scroll distance and the column position.
  local distance, newColumn, fileChanged, limitExceeded = F.GetScrollDistance(command, useCount)

  if fileChanged then
    return
  elseif limitExceeded then
    if scrollWin == 1 and config.centered then
      vim.cmd('norm! zz')
    end
    return
  end

  -- Perform the scroll.
  if distance > 0 then
    F.ScrollDown(distance, scrollWin, delay, slowdown)
  elseif distance < 0 then
    F.ScrollUp(distance, scrollWin, delay, slowdown)
  else
    F.RelativeScroll(command, delay, slowdown)
  end

  -- Change the cursor column position if required.
  if newColumn ~= -1 then
    vim.fn.cursor(vim.fn.line('.'), newColumn)
  end

  -- Restore options.
  vim.opt.lazyredraw = saved.lazyredraw
end

return S
