local M = {}

local config = require('cinnamon.config')
local utils = require('cinnamon.utils')
local fn = require('cinnamon.functions')
local motions = require('cinnamon.motions')

local saved_guicursor = vim.opt.guicursor:get()
local warning_given = false

M.scroll = function(command, scroll_win, use_count, delay_length, deprecated_arg)
  if deprecated_arg ~= nil and not warning_given then
    utils.error_msg('Argument 5 for the Cinnamon Scroll API function is now deprecated.', 'Warning', 'WARN')
    warning_given = true
  end

  -- Convert arguments to boolean:
  local int_to_bool = function(val)
    if val == 0 then
      return false
    else
      return true
    end
  end

  -- Setting argument defaults:
  if not command then
    utils.error_msg('The command argument cannot be nil')
    return
  end
  scroll_win = int_to_bool(scroll_win or 0)
  use_count = int_to_bool(use_count or 0)
  if not delay_length or delay_length == -1 then
    delay_length = config.default_delay
  end

  -- Execute command if only moving one line/char.
  if utils.contains(motions.no_scroll, command) and vim.v.count1 == 1 then
    vim.cmd('norm! ' .. command)
    return
  end

  -- Check if command is a mouse wheel scroll.
  local scroll_wheel = false
  if utils.contains(motions.scroll_wheel, command) then
    scroll_wheel = true
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

  -- Get initial position values.
  local saved_view = vim.fn.winsaveview()
  local prev_filepath = vim.fn.getreg('%')
  local _, prev_lnum, prev_column, _, prev_curswant = unpack(vim.fn.getcurpos())
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

  -- Get final position values.
  local curpos = vim.fn.getcurpos()
  local filepath = vim.fn.getreg('%')
  local _, lnum, column, _, curswant = unpack(curpos)
  local winline = vim.fn.winline()
  local wincol = vim.fn.wincol()
  local distance = lnum - prev_lnum

  -- Check if the file changed or the scroll limit exceeded.
  if prev_filepath ~= filepath or math.abs(distance) > config.scroll_limit then
    if scroll_win and config.centered then
      vim.cmd('norm! zz')
    end
    restore_options()
    return
  end

  -- Restore the original view.
  vim.fn.winrestview(saved_view)

  -- Check if scrolled vertically and/or horizontally.
  local scrolled_window_vertically = false
  if winline - lnum ~= prev_winline - prev_lnum then
    scrolled_window_vertically = true
  end
  local scrolled_view_horizontally = false
  if wincol - column ~= prev_wincol - prev_column then
    scrolled_view_horizontally = true
  end

  -- Check if values have changed.
  if curswant == prev_curswant then
    column = -1
  end
  if wincol == prev_wincol then
    wincol = -1
  end

  -- Hide the cursor.
  local cursor_hidden = false
  if config.hide_cursor and vim.opt.termguicolors:get() then
    if vim.opt.guicursor:get() ~= 'a:CinnamonHideCursor' then
      saved_guicursor = vim.opt.guicursor:get()
    end
    vim.opt.guicursor = 'a:CinnamonHideCursor'
    cursor_hidden = true
  end

  -- Scroll vertically.
  if scroll_wheel then
    fn.scroll_wheel_vertically(command, distance, curpos, winline, delay_length)
  elseif scrolled_window_vertically or config.always_scroll or scroll_win or scroll_wheel then
    fn.scroll_vertically(distance, curpos, winline, scroll_win, delay_length)
  else
    fn.scroll_vertically(distance, curpos, winline, scroll_win, 0)
  end

  -- Scroll horizontally.
  if
    (scrolled_view_horizontally and config.horizontal_scroll or config.always_scroll) and vim.fn.foldclosed('.') == -1
  then
    fn.scroll_horizontally(column, wincol, math.ceil(delay_length / 3))
  else
    fn.scroll_horizontally(column, wincol, 0)
  end

  -- Restore the cursor.
  if cursor_hidden then
    vim.opt.guicursor = saved_guicursor
  end

  restore_options()
end

return M
