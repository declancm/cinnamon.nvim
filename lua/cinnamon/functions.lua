local F = {}

local options = require('cinnamon').options
local U = require('cinnamon.utils')

function F.CheckCommandErrors(command)
  -- If no search pattern, return an error if using a repeat search command.
  for _, item in pairs { 'n', 'N' } do
    if item == command then
      local pattern = vim.fn.getreg('/')
      if pattern == '' then
        U.ErrorMsg('The search pattern is empty')
        return true
      end
      if vim.fn.search(pattern, 'nw') == 0 then
        U.ErrorMsg('Pattern not found: ' .. vim.fn.getreg('/'), 'E486')
        return true
      end
    end
  end

  -- If no word under cursor, return an error if using a word-near-cursor search command.
  for _, item in pairs { '*', '#', 'g*', 'g#' } do
    if item == command then
      -- Check if string is empty or only whitespace.
      if vim.fn.getline('.'):match('^%s*$') then
        U.ErrorMsg('No string under cursor', 'E348')
        return true
      end
    end
  end

  -- If no word under cursor, return an error if using a goto command.
  for _, item in pairs { 'gd', 'gD', '1gd', '1gD' } do
    if item == command then
      -- Check if string is empty or only whitespace.
      if vim.fn.getline('.'):match('^%s*$') then
        U.ErrorMsg('No identifier under cursor', 'E349')
        return true
      end
    end
  end

  -- If no errors, return false.
  return false
end

local function CheckForFold(counter)
  local foldStart = vim.fn.foldclosed('.')
  -- If a fold exists, add the length to the counter.
  if foldStart ~= -1 then
    local foldSize = vim.fn.foldclosedend(foldStart) - foldStart
    counter = counter + foldSize
  end
  return counter
end

function F.ScrollDown(distance, scrollWin, delay, slowdown)
  -- Center the screen.
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if vim.fn.winline() > halfHeight then
    F.CenterScreen(distance, scrollWin, delay, slowdown)
  end

  -- Scroll.
  local counter = 1
  while counter <= distance do
    counter = CheckForFold(counter)
    vim.cmd('norm! j')
    if scrollWin == 1 then
      if options.centered then
        -- Stay at the center of the screen.
        if vim.fn.winline() > halfHeight then
          vim.cmd('silent exe "norm! \\<C-E>"')
        end
      else
        -- Scroll the window if the current line is not within 'scrolloff'.
        if not (vim.fn.winline() <= vim.o.so + 1 or vim.fn.winline() >= vim.fn.winheight('%') - vim.o.so) then
          vim.cmd('silent exe "norm! \\<C-E>"')
        end
      end
    end
    counter = counter + 1
    F.Delay(distance - counter, delay, slowdown)
  end

  -- Center the screen.
  F.CenterScreen(0, scrollWin, delay, slowdown)
end

function F.ScrollUp(distance, scrollWin, delay, slowdown)
  -- Center the screen.
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if vim.fn.winline() < halfHeight then
    F.CenterScreen(-distance, scrollWin, delay, slowdown)
  end

  -- Scroll.
  local counter = 1
  while counter <= -distance do
    counter = CheckForFold(counter)
    vim.cmd('norm! k')
    if scrollWin == 1 then
      if options.centered then
        -- Stay at the center of the screen.
        if vim.fn.winline() < halfHeight then
          vim.cmd('silent exe "norm! \\<C-Y>"')
        end
      else
        -- Scroll the window if the current line is not within 'scrolloff'.
        if not (vim.fn.winline() <= vim.o.so + 1 or vim.fn.winline() >= vim.fn.winheight('%') - vim.o.so) then
          vim.cmd('silent exe "norm! \\<C-Y>"')
        end
      end
    end
    counter = counter + 1
    F.Delay(-distance + counter, delay, slowdown)
  end

  -- Center the screen.
  F.CenterScreen(0, scrollWin, delay, slowdown)
end

function F.GetScrollDistance(command, useCount)
  -- Variables.
  local cmdline, newRow, newColumn, newCurswant

  -- Create a backup for the current window view.
  local savedView = vim.fn.winsaveview()

  -- Get the cursor position.
  local prevPosition = vim.fn.getcurpos()
  local _, prevRow, _, _, prevCurswant = unpack(prevPosition)
  local prevFile = vim.fn.getreg('%')

  -- Perform the command.
  if command == 'definition' then
    require('vim.lsp.buf').definition()
    vim.cmd('sleep 100m')
  elseif command == 'declaration' then
    require('vim.lsp.buf').declaration()
    vim.cmd('sleep 100m')
  elseif useCount ~= 0 and vim.v.count > 0 then
    vim.cmd('norm! ' .. vim.v.count .. command)
  else
    vim.cmd('norm! ' .. command)
  end

  -- If searching within a fold, open the fold.
  for _, item in pairs { 'n', 'N', '*', '#', 'g*', 'g#' } do
    if command == item and vim.fn.foldclosed('.') ~= -1 then
      vim.cmd('norm! zo')
    end
  end

  -- Get the new cursor position.
  if not cmdline then
    _, newRow, newColumn, _, newCurswant = unpack(vim.fn.getcurpos())
  end

  -- Check if the file has changed.
  if prevFile ~= vim.fn.getreg('%') then
    -- Center the screen.
    vim.cmd('norm! zz')
    return 0, -1, true, false
  end

  -- Calculate the vertical movement distance.
  local distance = newRow - prevRow

  -- Check if the distance is too long.
  local scrollLimit = options.scroll_limit
  if distance > scrollLimit or distance < -scrollLimit then
    return 0, -1, false, true
  end

  -- Get the new column position if 'prevCurswant' has changed.
  if prevCurswant == newCurswant then
    newColumn = -1
  end

  -- Restore the window view.
  vim.fn.winrestview(savedView)
  return distance, newColumn, false, false
end

function F.Delay(remaining, delay, slowdown)
  vim.cmd('redraw')

  -- Don't create a delay when scrolling comleted.
  if remaining <= 0 then
    vim.cmd('redraw')
    return
  end

  -- Increase the delay near the end of the scroll.
  if remaining <= 4 and slowdown == 1 then
    vim.cmd('sleep ' .. delay * (5 - remaining) .. 'm')
  else
    vim.cmd('sleep ' .. delay .. 'm')
  end
end

function F.CenterScreen(remaining, scrollWin, delay, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if scrollWin == 1 and options.centered then
    local prevLine = vim.fn.winline()

    while vim.fn.winline() > halfHeight do
      vim.cmd('silent exe "norm! \\<C-E>"')
      local newLine = vim.fn.winline()
      F.Delay(newLine - halfHeight + remaining, delay, slowdown)
      -- If line isn't changing, break the endless loop.
      if newLine == prevLine then
        break
      end
      prevLine = newLine
    end

    while vim.fn.winline() < halfHeight do
      vim.cmd('silent exe "norm! \\<C-Y>"')
      local newLine = vim.fn.winline()
      F.Delay(halfHeight - newLine + remaining, delay, slowdown)
      -- If line isn't changing, break the endless loop.
      if newLine == prevLine then
        break
      end
      prevLine = newLine
    end
  end
end

return F
