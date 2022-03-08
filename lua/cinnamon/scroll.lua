local M = {}

-- Cinnamon.Scroll('arg1', 'arg2', 'arg3', 'arg4', 'arg5', 'arg6')

-- arg1 = The movement command (eg. 'gg'). This argument is required as there's\
--        no default value.
-- arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
-- arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
-- arg4 = Length of delay between lines (in ms). Default is 5.
-- arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.
-- arg6 = Max number of lines before scrolling is skipped. Mainly just for big\
--        commands such as 'gg' and 'G'. Default is 150.

-- Note: Each argument is a string separated by a comma.

function M.Scroll(movement, scrollWin, useCount, delay, slowdown, maxLines)
  -- Setting defaults:
  scrollWin = scrollWin or 1
  useCount = useCount or 0
  delay = delay or 5
  slowdown = slowdown or 1
  maxLines = maxLines or 150
  -- Don't waste time performing the whole function if only moving one line.
  if (movement == 'j' or movement == 'k') and vim.v.count1 == 1 then
    vim.cmd('norm! ' .. movement)
    return
  end
  -- Get the scroll distance and the column position.
  local measurements = require('cinnamon.scroll').MovementDistance(movement, useCount)
  local distance = measurements[1]
  local newColumn = measurements[2]
  -- If there is no vertical movement, return.
  if distance == 0 then
    -- Center the screen if it's not centered.
    if scrollWin == 1 and vim.g.cinnamon_centered == 1 then
      vim.cmd 'normal! zz'
    end
    -- Change the cursor column position if required.
    if newColumn ~= -1 then
      vim.fn.cursor(vim.fn.line '.', newColumn)
    end
    return
  end
  -- It the distance is too long, perform the movement without the scroll.
  if distance > maxLines or distance < -maxLines then
    if useCount == 1 and vim.v.count1 > 1 then
      vim.cmd('norm! ' .. vim.v.count1 .. movement)
    else
      vim.cmd('norm! ' .. movement)
    end
    return
  end
  -- Perform the scroll.
  if distance > 0 then
    require('cinnamon.scroll').ScrollDown(distance, delay, scrollWin, slowdown)
  else
    require('cinnamon.scroll').ScrollUp(distance, delay, scrollWin, slowdown)
  end
  -- Center the screen if it's not centered.
  require('cinnamon.scroll').CenterScreen(0, scrollWin, delay, slowdown)
  -- Change the cursor column position if required.
  if newColumn ~= -1 then
    vim.fn.cursor(vim.fn.line '.', newColumn)
  end
end

function M.ScrollDown(distance, delay, scrollWin, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if vim.fn.winline() > halfHeight then
    require('cinnamon.scroll').CenterScreen(distance, scrollWin, delay, slowdown)
  end
  local counter = 1
  while counter <= distance do
    counter = require('cinnamon.scroll').CheckFold(counter)
    vim.cmd 'norm! j'
    if scrollWin == 1 then
      if vim.g.cinnamon_centered == 1 then
        -- Stay at the center of the screen.
        if vim.fn.winline() > halfHeight then
          vim.cmd [[silent exec "norm! \<C-E>"]]
        end
      else
        -- Scroll the window if the current line is not within the scrolloff
        -- borders.
        if not (vim.fn.winline() <= vim.o.so + 1 or vim.fn.winline() >= vim.fn.winheight '%' - vim.o.so) then
          vim.cmd [[silent exec "norm! \<C-E>"]]
        end
      end
    end
    counter = counter + 1
    require('cinnamon.scroll').SleepDelay(distance - counter, delay, slowdown)
  end
end

function M.ScrollUp(distance, delay, scrollWin, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if vim.fn.winline() < halfHeight then
    require('cinnamon.scroll').CenterScreen(-distance, scrollWin, delay, slowdown)
  end
  local counter = 1
  while counter <= -distance do
    counter = require('cinnamon.scroll').CheckFold(counter)
    vim.cmd 'norm! k'
    if scrollWin == 1 then
      if vim.g.cinnamon_centered == 1 then
        -- Stay at the center of the screen.
        if vim.fn.winline() < halfHeight then
          vim.cmd [[silent exec "norm! \<C-Y>"]]
        end
      else
        -- Scroll the window if the current line is not within the scrolloff
        -- borders.
        if not (vim.fn.winline() <= vim.o.so + 1 or vim.fn.winline() >= vim.fn.winheight '%' - vim.o.so) then
          vim.cmd [[silent exec "norm! \<C-Y>"]]
        end
      end
    end
    counter = counter + 1
    require('cinnamon.scroll').SleepDelay(-distance + counter, delay, slowdown)
  end
end

function M.CheckFold(counter)
  local foldStart = vim.fn.foldclosed '.'
  -- If a fold exists, add the length to the counter.
  if foldStart ~= -1 then
    local foldSize = vim.fn.foldclosedend(foldStart) - foldStart
    counter = counter + foldSize
  end
  return counter
end

function M.MovementDistance(movement, useCount)
  local newColumn = -1
  -- Create a backup for the current window view.
  local viewSaved = vim.fn.winsaveview()
  -- Calculate distance by subtracting the original position from the new
  -- position after performing the movement.
  local row = vim.fn.getcurpos()[2]
  local curswant = vim.fn.getcurpos()[5]
  local file = vim.fn.bufname '%'
  if useCount == 1 and vim.v.count1 > 1 then
    vim.cmd('norm! ' .. vim.v.count1 .. movement)
  else
    vim.cmd('norm! ' .. movement)
  end
  local newRow = vim.fn.getcurpos()[2]
  local newFile = vim.fn.bufname '%'
  -- Check if the file has changed.
  if file ~= newFile then
    -- Center the screen.
    vim.cmd 'norm! zz'
    return { 0, -1 }
  end
  -- Calculate the movement distance.
  local distance = newRow - row
  -- Get the new column position if 'curswant' has changed.
  if curswant ~= vim.fn.getcurpos()[5] then
    newColumn = vim.fn.getcurpos()[3]
  end
  -- Restore the window view.
  vim.fn.winrestview(viewSaved)
  return { distance, newColumn }
end

function M.SleepDelay(remaining, delay, slowdown)
  vim.cmd 'redraw'
  -- Don't create a delay when scrolling comleted.
  if remaining <= 0 then
    vim.cmd 'redraw'
    return
  end
  -- Increase the delay near the end of the scroll.
  if remaining <= 4 and slowdown == 1 then
    vim.cmd('sleep ' .. delay * (5 - remaining) .. 'm')
  else
    vim.cmd('sleep ' .. delay .. 'm')
  end
end

function M.CenterScreen(remaining, scrollWin, delay, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if scrollWin == 1 and vim.g.cinnamon_centered == 1 then
    local prevLine = vim.fn.winline()
    while vim.fn.winline() > halfHeight do
      vim.cmd [[silent exec "norm! \<C-E>"]]
      local newLine = vim.fn.winline()
      require('cinnamon.scroll').SleepDelay(newLine - halfHeight + remaining, delay, slowdown)
      -- If line isn't changing, break the endless loop.
      if newLine == prevLine then
        break
      end
      prevLine = newLine
    end
    while vim.fn.winline() < halfHeight do
      vim.cmd [[silent exec "norm! \<C-Y>"]]
      local newLine = vim.fn.winline()
      require('cinnamon.scroll').SleepDelay(halfHeight - newLine + remaining, delay, slowdown)
      -- If line isn't changing, break the endless loop.
      if newLine == prevLine then
        break
      end
      prevLine = newLine
    end
  end
end

return M
