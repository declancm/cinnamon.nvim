local fn = {}

local config = require('cinnamon.config')
local utils = require('cinnamon.utils')
local motions = require('cinnamon.motions')

local create_delay = function(delay_length)
  if delay_length == 0 then
    return
  end
  delay_length = math.floor(delay_length)
  if delay_length == 0 then
    delay_length = 1
  end

  -- TODO: find an alternative to 'sleep'
  vim.cmd('sleep ' .. delay_length .. 'm')

  vim.cmd('redraw')
end

fn.check_command_errors = function(command)
  -- If no search pattern, return an error if using a repeat search command.
  if utils.contains(motions.search_repeat, command) then
    local pattern = vim.fn.getreg('/')
    if pattern == '' then
      utils.error_msg('The search pattern is empty')
      return true
    end
    if vim.fn.search(pattern, 'nw') == 0 then
      utils.error_msg('Pattern not found: ' .. vim.fn.getreg('/'), 'E486')
      return true
    end
  end

  -- If no word under cursor, return an error if using a word-near-cursor search command.
  if utils.contains(motions.search_cursor, command) then
    -- Check if string is empty or only whitespace.
    if vim.fn.getline('.'):match('^%s*$') then
      utils.error_msg('No string under cursor', 'E348')
      return true
    end
  end

  -- If no word under cursor, return an error if using a goto declaration command.
  if utils.contains(motions.goto_declaration, command) then
    -- Check if string is empty or only whitespace.
    if vim.fn.getline('.'):match('^%s*$') then
      utils.error_msg('No identifier under cursor', 'E349')
      return true
    end
  end

  -- If no errors, return false.
  return false
end

fn.scroll_screen = function(delay_length, target_line)
  target_line = target_line or math.ceil(vim.api.nvim_win_get_height(0) / 2)
  if target_line == -1 then
    return
  end

  local prev_line = vim.fn.winline()

  -- Scroll up the screen.
  while vim.fn.winline() > target_line do
    vim.cmd('silent exe "norm! \\<C-E>"')
    local new_line = vim.fn.winline()
    create_delay(delay_length)
    if new_line == prev_line then
      break
    end
    prev_line = new_line
  end

  -- Scroll down the screen.
  while vim.fn.winline() < target_line do
    vim.cmd('silent exe "norm! \\<C-Y>"')
    local new_line = vim.fn.winline()
    create_delay(delay_length)
    if new_line == prev_line then
      break
    end
    prev_line = new_line
  end
end

fn.scroll_horizontally = function(delay_length, wincol, column)
  if wincol == -1 and column == -1 then
    return
  end

  if column ~= -1 then
    local prev_column = vim.fn.getcurpos()[3]
    while vim.fn.getcurpos()[3] < column do
      vim.cmd('norm! l')
      create_delay(delay_length)
      if vim.fn.getcurpos()[3] == prev_column then
        break
      end
    end
    while vim.fn.getcurpos()[3] > column do
      vim.cmd('norm! h')
      create_delay(delay_length)
      if vim.fn.getcurpos()[3] == prev_column then
        break
      end
    end
  end

  if wincol ~= -1 then
    local prev_wincol = vim.fn.wincol()

    while vim.fn.wincol() > wincol do
      vim.cmd('norm! zl')
      local new_wincol = vim.fn.wincol()
      create_delay(delay_length)
      if new_wincol == prev_wincol then
        break
      end
      prev_wincol = new_wincol
    end

    while vim.fn.wincol() < wincol do
      vim.cmd('norm! zh')
      local new_wincol = vim.fn.wincol()
      create_delay(delay_length)
      if new_wincol == prev_wincol then
        break
      end
      prev_wincol = new_wincol
    end
  end
end

fn.scroll_down = function(curpos, scroll_win, delay_length)
  local lnum = curpos[2]
  local win_height = vim.api.nvim_win_get_height(0)

  -- Center the screen.
  local half_height = math.ceil(win_height / 2)
  if vim.fn.winline() > half_height and scroll_win and config.centered then
    fn.scroll_screen(delay_length)
  end

  -- Scroll.
  while vim.fn.getcurpos()[2] < lnum do
    -- Check if movement ends in the current fold.
    if vim.fn.foldclosedend('.') ~= -1 and vim.fn.foldclosedend('.') > lnum then
      vim.fn.setpos('.', curpos)
      return
    end

    local prev_lnum = vim.fn.getcurpos()[2]
    vim.cmd('norm! j')
    local current_winline = vim.fn.winline()

    if scroll_win then
      if config.centered then
        if current_winline > half_height then
          vim.cmd('silent exe "norm! \\<C-E>"')
        end
      else
        -- Scroll the window if the current line is not within 'scrolloff'.
        local scrolloff
        if vim.opt_local.so:get() ~= -1 then
          scrolloff = vim.opt_local.so:get()
        else
          scrolloff = vim.opt.so:get()
        end
        if current_winline > scrolloff + 1 and current_winline < win_height - scrolloff then
          vim.cmd('silent exe "norm! \\<C-E>"')
        end
      end
    end

    -- Break if line number not changing.
    if vim.fn.getcurpos()[2] == prev_lnum then
      break
    end

    create_delay(delay_length)
  end
end

fn.scroll_up = function(curpos, scroll_win, delay_length)
  local lnum = curpos[2]
  local win_height = vim.api.nvim_win_get_height(0)

  -- Center the screen.
  local half_height = math.ceil(win_height / 2)
  if vim.fn.winline() < half_height and scroll_win and config.centered then
    fn.scroll_screen(delay_length)
  end

  -- Scroll.
  while vim.fn.getcurpos()[2] > lnum do
    -- Check if movement ends in the current fold.
    if vim.fn.foldclosed('.') ~= -1 and vim.fn.foldclosed('.') < lnum then
      vim.fn.setpos('.', curpos)
      return
    end

    local prev_lnum = vim.fn.getcurpos()[2]
    vim.cmd('norm! k')
    local current_winline = vim.fn.winline()

    if scroll_win then
      if config.centered then
        if current_winline < half_height then
          vim.cmd('silent exe "norm! \\<C-Y>"')
        end
      else
        -- Scroll the window if the current line is not within 'scrolloff'.
        local scrolloff
        if vim.opt_local.so:get() ~= -1 then
          scrolloff = vim.opt_local.so:get()
        else
          scrolloff = vim.opt.so:get()
        end
        if current_winline > scrolloff + 1 and current_winline < win_height - scrolloff then
          vim.cmd('silent exe "norm! \\<C-Y>"')
        end
      end
    end

    -- Break if line number not changing.
    if vim.fn.getcurpos()[2] == prev_lnum then
      break
    end

    create_delay(delay_length)
  end
end

return fn
