local M = {}

local config = require('cinnamon.config')
local utils = require('cinnamon.utils')
local fn = require('cinnamon.functions')
local motions = require('cinnamon.motions')

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

  -- Setting argument defaults:
  if not command then
    utils.error_msg('The command argument cannot be nil')
    return
  end
  scroll_win = scroll_win or 1
  use_count = use_count or 0
  delay = delay or 5
  slowdown = slowdown or 1

  -- Execute command if only moving one line.
  if utils.contains(motions.up_down, command) then
    vim.cmd('norm! ' .. command)
    return
  end

  -- Save and set options.
  local saved = {}
  saved.lazyredraw = vim.opt.lazyredraw:get()
  vim.opt.lazyredraw = false

  -- Restore options.
  local restore_options = function()
    vim.opt.lazyredraw = saved.lazyredraw
  end

  -- Check if scroll is for a vertical movement or just window scrolling.
  if utils.contains(motions.relative_scroll, command) then
    -- Execute command if used with a count.
    if use_count and vim.v.count > 0 then
      vim.cmd('norm! ' .. vim.v.count .. command)
      restore_options()
      return
    end

    -- Scroll the window.
    fn.relative_scroll(command, delay, slowdown)

    -- Change the cursor column position if required.
    if utils.contains(motions.relative_scroll_caret, command) then
      vim.cmd('norm! ^')
    end
  else
    -- Check for any errors with the command.
    if fn.check_command_errors(command) then
      restore_options()
      return
    end

    -- Get the scroll distance and the final column position.
    local distance, new_column, file_changed, limit_exceeded = fn.get_scroll_distance(command, use_count, scroll_win)
    if file_changed or limit_exceeded then
      restore_options()
      return
    end

    -- Scroll the cursor.
    if distance > 0 then
      fn.scroll_down(distance, scroll_win, delay, slowdown)
    elseif distance < 0 then
      fn.scroll_up(distance, scroll_win, delay, slowdown)
    end

    -- Change the cursor column position if required.
    if new_column ~= -1 then
      vim.fn.cursor(vim.fn.line('.'), new_column)
    end
  end

  restore_options()
end

return M
