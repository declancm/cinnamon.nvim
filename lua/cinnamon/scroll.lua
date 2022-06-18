local M = {}

local config = require('cinnamon.config')
local utils = require('cinnamon.utils')
local fn = require('cinnamon.functions')
local motions = require('cinnamon.motions')

local warning_counter = 0

M.scroll = function(command, scroll_win, use_count, delay_length, deprecated_arg)
  if deprecated_arg ~= nil and warning_counter < 1 then
    utils.error_msg('Argument 5 for the Cinnamon Scroll API function is now deprecated.', 'Warning', 'WARN')
    warning_counter = warning_counter + 1
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
  local prev_file = vim.fn.getreg('%')
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

  local curpos = vim.fn.getcurpos()
  local _, lnum, column, _, curswant = unpack(curpos)
  local winline = vim.fn.winline()
  local wincol = vim.fn.wincol()
  local distance = lnum - prev_lnum

  -- Check if the file has changed.
  if prev_file ~= vim.fn.getreg('%') then
    vim.cmd('norm! zz')
    restore_options()
    return
  end

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
  if winline - lnum == prev_winline - prev_lnum and not config.always_scroll then
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

  vim.fn.winrestview(saved_view)

  -- Hide the cursor.
  local saved_guicursor
  if config.hide_cursor and vim.opt.termguicolors:get() then
    saved_guicursor = vim.opt.guicursor:get()
    vim.cmd('highlight Cursor blend=100')
    vim.opt.guicursor:append('a:Cursor/lCursor')
  end

  -- Scroll the cursor.
  if distance > 0 then
    fn.scroll_down(curpos, scroll_win, delay_length)
  elseif distance < 0 then
    fn.scroll_up(curpos, scroll_win, delay_length)
  end

  -- Scroll the screen.
  if not scroll_win then
    fn.scroll_screen(delay_length, winline)
  end

  -- Scroll horizontally.
  if (scrolled_horizontally and config.horizontal_scroll or config.always_scroll) and vim.fn.foldclosed('.') == -1 then
    fn.scroll_horizontally(math.ceil(delay_length / 3), wincol, column)
  else
    fn.scroll_horizontally(0, wincol, column)
  end

  -- Restore the cursor.
  if config.hide_cursor and vim.opt.termguicolors:get() then
    vim.opt.guicursor = saved_guicursor
  end

  restore_options()
end

return M
