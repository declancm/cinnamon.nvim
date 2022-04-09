local M = {}

local config = require('cinnamon.config')
local utils = require('cinnamon.utils')
local fn = require('cinnamon.functions')
local motions = require('cinnamon.motions')

-- TODO: add doc files.

--[[

require('cinnamon.scroll').scroll(arg1, arg2, arg3, arg4, arg5, arg6)

arg1 = A string containing the normal mode movement command.
  * To use the go-to-definition LSP function, use 'definition' (or 'declaration'
    for go-to-declaration).
arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
arg4 = Length of delay between lines (in ms). Default is 5.
arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

Note: arg1 is a string while the others are integers.

]]

M.scroll = function(command, scroll_win, use_count, delay, slowdown)
  if config.disable then
    utils.error_msg('Cinnamon is disabled')
    return
  end

  -- Check if command argument exists.
  if not command then
    utils.error_msg('The command argument cannot be nil')
    return
  end

  -- Execute command if only moving one line.
  if utils.within(command, motions.up_down) then
    vim.cmd('norm! ' .. command)
    return
  end

  -- Setting argument defaults:
  scroll_win = scroll_win or 1
  use_count = use_count or 0
  delay = delay or 5
  slowdown = slowdown or 1

  -- Execute command if using a relative scroll command with a count.
  if utils.within(command, motions.relative_scroll) and use_count and vim.v.count > 0 then
    vim.cmd('norm! ' .. vim.v.count .. command)
    return
  end

  -- Save options.
  local saved = {}
  saved.lazyredraw = vim.opt.lazyredraw:get()

  -- Set options.
  vim.opt.lazyredraw = false

  -- Check for any errors with the command.
  if fn.check_command_errors(command) then
    return
  end

  -- Get the scroll distance and the column position.
  local distance, new_column, file_changed, limit_exceeded = fn.get_scroll_distance(command, use_count)

  if file_changed then
    return
  elseif limit_exceeded then
    if scroll_win == 1 and config.centered then
      vim.cmd('norm! zz')
    end
    return
  end

  -- Perform the scroll.
  if distance > 0 then
    fn.scroll_down(distance, scroll_win, delay, slowdown)
  elseif distance < 0 then
    fn.scroll_up(distance, scroll_win, delay, slowdown)
  else
    fn.relative_scroll(command, delay, slowdown)
  end

  -- Change the cursor column position if required.
  if new_column ~= -1 then
    vim.fn.cursor(vim.fn.line('.'), new_column)
  elseif utils.within(command, motions.relative_scroll_caret) then
    vim.cmd('norm! ^')
  end

  -- Restore options.
  vim.opt.lazyredraw = saved.lazyredraw
end

return M
