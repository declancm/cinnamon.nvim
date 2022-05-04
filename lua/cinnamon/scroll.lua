local M = {}

local config = require('cinnamon.config')
local utils = require('cinnamon.utils')
local fn = require('cinnamon.functions')
local motions = require('cinnamon.motions')

local debugging = false

--[[

require('cinnamon.scroll').scroll(arg1, arg2, arg3, arg4, arg5, arg6)

arg1 = A string containing the normal mode movement commands.
  * To use the go-to-definition LSP function, use 'definition' (or 'declaration'
    for go-to-declaration).
arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 0.
arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
arg4 = Length of delay between each line (in ms). Default is the 'default_delay' config value.
arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

Note: arg1 is a string while the others are integers.

]]

M.scroll = function(command, scroll_win, use_count, delay, slowdown)
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
  scroll_win = int_to_bool(scroll_win or 0)
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

  local saved_view = vim.fn.winsaveview()
  local _, prev_row, prev_column, _, prev_curswant = unpack(vim.fn.getcurpos())
  local prev_file = vim.fn.getreg('%')
  local prev_winline = vim.fn.winline()
  local prev_wincol = vim.fn.wincol()

  -- Perform the command.
  if command == 'definition' or command == 'declaration' then
    require('vim.lsp.buf')[command]()
    vim.cmd('sleep 100m')
  elseif use_count and vim.v.count > 0 then
    vim.cmd('norm! ' .. vim.v.count .. command)
  else
    vim.cmd('norm! ' .. command)
  end

  -- If searching contains a fold, open the fold.
  if utils.contains(motions.search, command) and vim.fn.foldclosed('.') ~= -1 then
    vim.cmd('norm! zo')
  end

  -- Check if the file has changed.
  if prev_file ~= vim.fn.getreg('%') then
    vim.cmd('norm! zz')
    restore_options()
    return
  end

  local _, row, column, _, curswant = unpack(vim.fn.getcurpos())
  local winline = vim.fn.winline()
  local wincol = vim.fn.wincol()
  local distance = row - prev_row

  -- Check if scroll limit has been exceeded.
  if distance > config.scroll_limit or distance < -config.scroll_limit then
    if scroll_win and config.centered then
      vim.cmd('norm! zz')
    end
    restore_options()
    return
  end

  -- Check if scrolled horizontally.
  local scrolled_horizontally = false
  if wincol - column ~= prev_wincol - prev_column then
    scrolled_horizontally = true
  end

  -- Check if scrolled vertically.
  if winline - row == prev_winline - prev_row and not config.always_scroll then
    if not scrolled_horizontally and not scroll_win and not vim.opt.wrap:get() then
      restore_options()
      return
    end
  end

  -- Check if values have changed.
  if curswant == prev_curswant then
    column = -1
  end
  if winline == prev_winline then
    winline = -1
  end
  if wincol == prev_winline then
    wincol = -1
  end

  if debugging then
    print(string.format('distance: %s, column: %s, winline: %s, wincol: %s', distance, column, winline, wincol))
  end

  vim.fn.winrestview(saved_view)

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
  if scrolled_horizontally and config.horizontal_scroll or config.always_scroll then
    fn.scroll_horizontally(delay / 2, slowdown, wincol, column)
  else
    fn.scroll_horizontally(0, 0, wincol, column)
  end

  restore_options()
end

return M
