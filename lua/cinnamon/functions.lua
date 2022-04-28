local fn = {}

local config = require('cinnamon.config')
local utils = require('cinnamon.utils')
local motions = require('cinnamon.motions')

local check_for_fold = function(counter)
  local fold_start = vim.fn.foldclosed('.')

  -- If a fold exists, add the length to the counter.
  if fold_start ~= -1 then
    local fold_size = vim.fn.foldclosedend(fold_start) - fold_start
    counter = counter + fold_size
  end
  return counter
end

local create_delay = function(remaining, delay, slowdown)
  if delay == 0 then
    return
  end
  delay = math.floor(delay)
  if delay == 0 then
    delay = 1
  end

  -- Don't create a delay when scrolling comleted.
  if remaining <= 0 then
    return
  end

  -- TODO: find an alternative to 'sleep'

  -- Increase the delay near the end of the scroll.
  if remaining <= 4 and slowdown then
    vim.cmd('sleep ' .. delay * (5 - remaining) .. 'm')
  else
    vim.cmd('sleep ' .. delay .. 'm')
  end

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

fn.scroll_screen = function(remaining, delay, slowdown, target_line)
  target_line = target_line or math.ceil(vim.api.nvim_win_get_height(0) / 2)
  if target_line == -1 then
    return
  end

  local prev_line = vim.fn.winline()

  -- Scroll up the screen.
  while vim.fn.winline() > target_line do
    vim.cmd('silent exe "norm! \\<C-E>"')
    local new_line = vim.fn.winline()
    create_delay(new_line - target_line + remaining, delay, slowdown)
    if new_line == prev_line then
      break
    end
    prev_line = new_line
  end

  -- Scroll down the screen.
  while vim.fn.winline() < target_line do
    vim.cmd('silent exe "norm! \\<C-Y>"')
    local new_line = vim.fn.winline()
    create_delay(target_line - new_line + remaining, delay, slowdown)
    if new_line == prev_line then
      break
    end
    prev_line = new_line
  end
end

fn.scroll_horizontally = function(delay, slowdown, wincol, column)
  if wincol == -1 and column == -1 then
    return
  end

  if column ~= -1 then
    local distance = column - vim.fn.getcurpos()[3]
    local counter = 1
    if distance > 0 then
      while counter <= distance do
        vim.cmd('norm! l')
        counter = counter + 1
        create_delay(distance - counter, delay, 0)
      end
    elseif distance < 0 then
      while counter <= -distance do
        vim.cmd('norm! h')
        counter = counter + 1
        create_delay(-distance + counter, delay, 0)
      end
    end
  end

  if wincol ~= -1 then
    local prev_wincol = vim.fn.wincol()

    while vim.fn.wincol() > wincol do
      vim.cmd('norm! zl')
      local new_wincol = vim.fn.wincol()
      create_delay(new_wincol - wincol, delay, slowdown)
      if new_wincol == prev_wincol then
        break
      end
      prev_wincol = new_wincol
    end

    while vim.fn.wincol() < wincol do
      vim.cmd('norm! zh')
      local new_wincol = vim.fn.wincol()
      create_delay(wincol - new_wincol, delay, slowdown)
      if new_wincol == prev_wincol then
        break
      end
      prev_wincol = new_wincol
    end
  end
end

fn.scroll_down = function(distance, winline, scroll_win, delay, slowdown)
  local win_height = vim.api.nvim_win_get_height(0)

  -- Center the screen.
  local half_height = math.ceil(win_height / 2)
  if vim.fn.winline() > half_height and scroll_win and config.centered then
    fn.scroll_screen(distance, delay, slowdown)
  end

  -- Scroll.
  local counter = 1
  while counter <= distance do
    counter = check_for_fold(counter)
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
    counter = counter + 1
    create_delay(distance - counter, delay, slowdown)
  end
end

fn.scroll_up = function(distance, winline, scroll_win, delay, slowdown)
  local win_height = vim.api.nvim_win_get_height(0)

  -- Center the screen.
  local half_height = math.ceil(win_height / 2)
  if vim.fn.winline() < half_height and scroll_win and config.centered then
    fn.scroll_screen(-distance, delay, slowdown)
  end

  -- Scroll.
  local counter = 1
  while counter <= -distance do
    counter = check_for_fold(counter)
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
    counter = counter + 1
    create_delay(-distance + counter, delay, slowdown)
  end
end

return fn
