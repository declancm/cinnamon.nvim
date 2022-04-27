local M = {}

local config = require('cinnamon.config')
local utils = require('cinnamon.utils')
local fn = require('cinnamon.functions')
local motions = require('cinnamon.motions')

--[[

require('cinnamon.scroll').scroll(arg1, arg2, arg3, arg4, arg5, arg6)

arg1 = A string containing the normal mode movement commands.
  * To use the go-to-definition LSP function, use 'definition' (or 'declaration'
    for go-to-declaration).
arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
arg4 = Length of delay between lines (in ms). Default is the 'default_delay' config value.
arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

Note: arg1 is a string while the others are integers.

]]

M.scroll = function(command, scroll_win, use_count, delay, slowdown)
  if config.disable then
    utils.error_msg('Cinnamon is disabled')
    return
  end

  -- Convert arguments to boolean:
  local int_to_bool = function(int)
    if int == 1 then
      return true
    elseif int == 0 then
      return false
    end
  end

  -- Setting argument defaults:
  if not command then
    utils.error_msg('The command argument cannot be nil')
    return
  end
  scroll_win = int_to_bool(scroll_win or 1)
  use_count = int_to_bool(use_count or 0)
  delay = delay or config.default_delay
  slowdown = int_to_bool(slowdown or 1)

  -- Execute command if only moving one line/char.
  if utils.contains(motions.no_scroll, command) and vim.v.count1 == 1 then
    vim.cmd('norm! ' .. command)
    return
  end

  -- Check for any errors with the command.
  if fn.check_command_errors(command) then
    return
  end

  -- Save and set options.
  local saved = {}
  saved.lazyredraw = vim.opt.lazyredraw:get()
  vim.opt.lazyredraw = false

  local restore_options = function()
    vim.opt.lazyredraw = saved.lazyredraw
  end

  -- Get the scroll distance and the final column position.
  local distance, column, winline, wincol, file_changed, limit_exceeded = fn.get_scroll_values(
    command,
    use_count,
    scroll_win
  )
  if file_changed or limit_exceeded then
    restore_options()
    return
  end

  -- Scroll the cursor.
  if distance > 0 then
    fn.scroll_down(distance, winline, scroll_win, delay, slowdown)
  elseif distance < 0 then
    fn.scroll_up(distance, winline, scroll_win, delay, slowdown)
  end

  -- Scroll the screen.
  if not scroll_win then
    fn.scroll_screen(0, delay, slowdown, winline)
  end

  -- Scroll horizontally.
  if distance == 0 then
    fn.scroll_screen_horizontally(delay, slowdown, wincol, column)
  else
    -- Set column position.
    if column ~= -1 then
      vim.fn.cursor(vim.fn.line('.'), column)
    end

    -- -- Set wincol position.
    -- if wincol ~= -1 then
    --   local current_wincol = vim.fn.wincol()
    --   if wincol > current_wincol then
    --     vim.cmd('norm! ' .. wincol - current_wincol .. 'zh')
    --   elseif wincol < current_wincol then
    --     vim.cmd('norm! ' .. wincol - current_wincol .. 'zl')
    --   end
    -- end
  end

  restore_options()
end

return M
