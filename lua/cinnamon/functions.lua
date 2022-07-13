local fn = {}

local config = require('cinnamon.config')
local utils = require('cinnamon.utils')
local motions = require('cinnamon.motions')

fn.check_command_errors = function(command)
  -- If no search pattern, return an error if using a repeat search command.
  if vim.tbl_contains(motions.search_repeat, command) then
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
  if vim.tbl_contains(motions.search_cursor, command) then
    -- Check if string is empty or only whitespace.
    if vim.fn.getline('.'):match('^%s*$') then
      utils.error_msg('No string under cursor', 'E348')
      return true
    end
  end

  -- If no word under cursor, return an error if using a goto declaration command.
  if vim.tbl_contains(motions.goto_declaration, command) then
    -- Check if string is empty or only whitespace.
    if vim.fn.getline('.'):match('^%s*$') then
      utils.error_msg('No identifier under cursor', 'E349')
      return true
    end
  end

  -- If no errors, return false.
  return false
end

fn.get_visual_distance = function(start_line, end_line)
  local distance = 0
  local i = start_line

  if start_line < end_line then
    while i < end_line do
      if vim.fn.foldclosedend(i) ~= -1 and vim.fn.foldclosedend(i) > end_line then
        return distance
      elseif vim.fn.foldclosedend(i) ~= -1 then
        -- If fold found, jump over it.
        local fold_size = vim.fn.foldclosedend(i) - i
        i = i + fold_size
      end

      distance = distance + 1
      i = i + 1
    end
  elseif start_line > end_line then
    while i > end_line do
      if vim.fn.foldclosed(i) ~= -1 and vim.fn.foldclosed(i) < end_line then
        return distance
      elseif vim.fn.foldclosed(i) ~= -1 then
        -- If fold found, jump over it.
        local fold_size = i - vim.fn.foldclosed(i)
        i = i - fold_size
      end

      distance = distance - 1
      i = i - 1
    end
  end

  return distance
end

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local create_delay = function(delay_length)
  if delay_length == 0 then
    return
  end
  delay_length = math.floor(delay_length)
  if delay_length == 0 then
    delay_length = 1
  end

  -- TODO: find a more accurate alternative to 'sleep'
  vim.cmd('sleep ' .. delay_length .. 'm')

  vim.cmd('redraw')
end

local scroll_screen = function(delay_length, target_line)
  target_line = target_line or math.ceil(vim.api.nvim_win_get_height(0) / 2)
  if target_line == -1 then
    return
  end

  local prev_line = vim.fn.winline()

  -- Scroll the cursor up.
  while vim.fn.winline() > target_line do
    vim.cmd('norm! ' .. t('<C-e>'))
    local new_line = vim.fn.winline()
    create_delay(delay_length)
    if new_line == prev_line then
      break
    end
    prev_line = new_line
  end

  -- Scroll the cursor down.
  while vim.fn.winline() < target_line do
    vim.cmd('norm! ' .. t('<C-y>'))
    local new_line = vim.fn.winline()
    create_delay(delay_length)
    if new_line == prev_line then
      break
    end
    prev_line = new_line
  end
end

local scroll_down = function(curpos, scroll_win, delay_length, scrolloff)
  local lnum = curpos[2]
  local win_height = vim.api.nvim_win_get_height(0)

  -- Center the screen.
  local half_height = math.ceil(win_height / 2)
  if vim.fn.winline() > half_height and scroll_win and config.centered then
    scroll_screen(delay_length)
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
          vim.cmd('norm! ' .. t('<C-e>'))
        end
      else
        -- Scroll the window if the current line is not within 'scrolloff'.
        if current_winline > scrolloff + 1 and current_winline < win_height - scrolloff then
          vim.cmd('norm! ' .. t('<C-e>'))
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

local scroll_up = function(curpos, scroll_win, delay_length, scrolloff)
  local lnum = curpos[2]
  local win_height = vim.api.nvim_win_get_height(0)

  -- Center the screen.
  local half_height = math.ceil(win_height / 2)
  if vim.fn.winline() < half_height and scroll_win and config.centered then
    scroll_screen(delay_length)
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
          vim.cmd('norm! ' .. t('<C-y>'))
        end
      else
        -- Scroll the window if the current line is not within 'scrolloff'.
        if current_winline > scrolloff + 1 and current_winline < win_height - scrolloff then
          vim.cmd('norm! ' .. t('<C-y>'))
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

fn.scroll_vertically = function(distance, curpos, winline, scroll_win, delay_length)
  -- Get the scrolloff value.
  local scrolloff
  if vim.opt_local.so:get() ~= -1 then
    scrolloff = vim.opt_local.so:get()
  else
    scrolloff = vim.opt.so:get()
  end

  -- Scroll the cursor vertically.
  if distance > 0 then
    scroll_down(curpos, scroll_win, delay_length, scrolloff)
  elseif distance < 0 then
    scroll_up(curpos, scroll_win, delay_length, scrolloff)
  end

  -- Scroll the screen vertically.
  if not scroll_win then
    scroll_screen(delay_length, winline)
  end
end

fn.scroll_wheel_vertically = function(command, distance, curpos, winline, delay_length)
  -- If line number and winline don't need to be changed, return.
  if distance == 0 and (vim.fn.winline() == winline) then
    return
  end

  local lnum = curpos[2]

  if command == t('<ScrollWheelDown>') then
    -- Scroll down.
    while vim.fn.getcurpos()[2] < lnum or vim.fn.winline() > winline do
      -- Check if movement ends in the current fold.
      if vim.fn.foldclosedend('.') ~= -1 and vim.fn.foldclosedend('.') > lnum then
        vim.fn.setpos('.', curpos)
        return
      end

      local prev_lnum = vim.fn.getcurpos()[2]
      local prev_winline = vim.fn.winline()

      -- TODO: Find alternative method.
      -- Stop scrolling past the bottom of the file due to bug with winrestview and scrolloff.
      local offset = 0
      local i = prev_lnum
      while i <= prev_lnum + vim.fn.winheight('.') - vim.fn.winline() + offset + 1 do
        -- Return if the current line doesn't exist.
        if not vim.fn.getbufline(vim.fn.bufname(), i)[1] then
          return
        end

        -- If fold found, jump over it.
        if vim.fn.foldclosedend(i) ~= -1 then
          local fold_size = vim.fn.foldclosedend(i) - i
          offset = offset + fold_size
          i = i + fold_size
        end

        i = i + 1
      end

      vim.cmd('norm! ' .. t('<C-e>'))

      -- Break if line number and winline not changing.
      if vim.fn.getcurpos()[2] == prev_lnum and vim.fn.winline() == prev_winline then
        break
      end

      create_delay(delay_length)
    end
  elseif command == t('<ScrollWheelUp>') then
    -- Scroll up.
    while vim.fn.getcurpos()[2] > lnum or vim.fn.winline() < winline do
      -- Check if movement ends in the current fold.
      if vim.fn.foldclosedend('.') ~= -1 and vim.fn.foldclosedend('.') < lnum then
        vim.fn.setpos('.', curpos)
        return
      end

      local prev_lnum = vim.fn.getcurpos()[2]
      local prev_winline = vim.fn.winline()

      vim.cmd('norm! ' .. t('<C-y>'))

      -- Break if line number and winline not changing.
      if vim.fn.getcurpos()[2] == prev_lnum and vim.fn.winline() == prev_winline then
        break
      end

      create_delay(delay_length)
    end
  end
end

fn.scroll_horizontally = function(column, wincol, delay_length)
  if wincol == -1 and column == -1 then
    return
  end

  -- Scroll the cursor horizontally.
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

  -- Scroll the screen horizontally.
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

return fn
