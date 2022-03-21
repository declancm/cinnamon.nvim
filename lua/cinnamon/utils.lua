local M = {}

--[[

require('cinnamon.utils').ScrollDown(distance, delay, scrollWin, slowdown)

Performs the actual scrolling movement downwards based on the given arguments.

]]

function M.ScrollDown(distance, delay, scrollWin, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if vim.fn.winline() > halfHeight then
    require('cinnamon.utils').CenterScreen(distance, scrollWin, delay, slowdown)
  end
  local counter = 1
  while counter <= distance do
    counter = require('cinnamon.utils').CheckFold(counter)
    vim.cmd 'norm! j'
    if scrollWin == 1 then
      if vim.g.__cinnamon_centered == true then
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
    require('cinnamon.utils').SleepDelay(distance - counter, delay, slowdown)
  end
end

--[[

require('cinnamon.utils').ScrollDown(distance, delay, scrollWin, slowdown)

Performs the actual scrolling movement upwards based on the given arguments.

]]

function M.ScrollUp(distance, delay, scrollWin, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if vim.fn.winline() < halfHeight then
    require('cinnamon.utils').CenterScreen(-distance, scrollWin, delay, slowdown)
  end
  local counter = 1
  while counter <= -distance do
    counter = require('cinnamon.utils').CheckFold(counter)
    vim.cmd 'norm! k'
    if scrollWin == 1 then
      if vim.g.__cinnamon_centered == true then
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
    require('cinnamon.utils').SleepDelay(-distance + counter, delay, slowdown)
  end
end

--[[

require('cinnamon.utils').CheckFold(counter)

The function will check if the current cursor position during the movement is a
fold. If so, add the full length of the fold to the cursor.

]]

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
  local prevFile = vim.fn.bufname '%'
  if useCount ~= 0 and vim.v.count1 > 1 then
    vim.cmd('norm! ' .. vim.v.count1 .. movement)
  else
    vim.cmd('norm! ' .. movement)
    -- vim.fn.feedkeys(movement, 'tn')
  end
  local newRow = vim.fn.getcurpos()[2]
  local newFile = vim.fn.bufname '%'
  -- Check if the file has changed.
  if prevFile ~= newFile then
    -- Center the screen.
    vim.cmd 'norm! zz'
    return 0, -1, true
  end
  -- Calculate the movement distance.
  local distance = newRow - row
  -- Get the new column position if 'curswant' has changed.
  if curswant ~= vim.fn.getcurpos()[5] then
    newColumn = vim.fn.getcurpos()[3]
  end
  -- Restore the window view.
  vim.fn.winrestview(viewSaved)
  return distance, newColumn, false
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

--[[

require('cinnamon.utils').CenterScreen(remaining, scrollWin, delay, slowdown)

If window scrolling and screen centering are enabled, center the screen smoothly.

]]

function M.CenterScreen(remaining, scrollWin, delay, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if scrollWin == 1 and vim.g.__cinnamon_centered == true then
    local prevLine = vim.fn.winline()
    while vim.fn.winline() > halfHeight do
      vim.cmd [[silent exec "norm! \<C-E>"]]
      local newLine = vim.fn.winline()
      require('cinnamon.utils').SleepDelay(newLine - halfHeight + remaining, delay, slowdown)
      -- If line isn't changing, break the endless loop.
      if newLine == prevLine then
        break
      end
      prevLine = newLine
    end
    while vim.fn.winline() < halfHeight do
      vim.cmd [[silent exec "norm! \<C-Y>"]]
      local newLine = vim.fn.winline()
      require('cinnamon.utils').SleepDelay(halfHeight - newLine + remaining, delay, slowdown)
      -- If line isn't changing, break the endless loop.
      if newLine == prevLine then
        break
      end
      prevLine = newLine
    end
  end
end

return M
