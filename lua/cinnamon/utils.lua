local M = {}

-- TODO: add a proper wait for lua functions instead of using a delay

function M.ErrorMsg(message, code)
  code = code or 'Error'
  vim.cmd("echohl ErrorMsg | echom '" .. code .. ': ' .. message .. "' | echohl None")
end

function M.CheckMovementErrors(command)
  -- If no search pattern, return an error if using a search command.
  for _, item in pairs { 'n', 'N' } do
    if item == command then
      local pattern = vim.fn.getreg('/')
      if pattern == '' then
        require('cinnamon.utils').ErrorMsg('The search pattern is empty')
        return true
      end
      if vim.fn.search(pattern, 'nw') == 0 then
        require('cinnamon.utils').ErrorMsg('Pattern not found: ' .. vim.fn.getreg('/'), 'E486')
        return true
      end
    end
  end
  -- If no word under cursor, return an error if using a search command.
  for _, item in pairs { '*', '#', 'g*', 'g#' } do
    if item == command then
      -- Check if string is empty or only whitespace.
      if vim.fn.getline('.'):match('^%s*$') then
        require('cinnamon.utils').ErrorMsg('No string under cursor', 'E348')
        return true
      end
    end
  end
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

function M.ScrollDown(distance, scrollWin, delay, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if vim.fn.winline() > halfHeight then
    require('cinnamon.utils').CenterScreen(distance, scrollWin, delay, slowdown)
  end
  local counter = 1
  while counter <= distance do
    counter = CheckForFold(counter)
    vim.cmd('norm! j')
    if scrollWin == 1 then
      if vim.g.__cinnamon_centered == true then
        -- Stay at the center of the screen.
        if vim.fn.winline() > halfHeight then
          vim.cmd([[silent exec "norm! \<C-E>"]])
        end
      else
        -- Scroll the window if the current line is not within 'scrolloff'.
        if not (vim.fn.winline() <= vim.o.so + 1 or vim.fn.winline() >= vim.fn.winheight('%') - vim.o.so) then
          vim.cmd([[silent exec "norm! \<C-E>"]])
        end
      end
    end
    counter = counter + 1
    require('cinnamon.utils').SleepDelay(distance - counter, delay, slowdown)
  end
  -- Center the screen.
  require('cinnamon.utils').CenterScreen(0, scrollWin, delay, slowdown)
end

function M.ScrollUp(distance, scrollWin, delay, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if vim.fn.winline() < halfHeight then
    require('cinnamon.utils').CenterScreen(-distance, scrollWin, delay, slowdown)
  end
  local counter = 1
  while counter <= -distance do
    counter = CheckForFold(counter)
    vim.cmd('norm! k')
    if scrollWin == 1 then
      if vim.g.__cinnamon_centered == true then
        -- Stay at the center of the screen.
        if vim.fn.winline() < halfHeight then
          vim.cmd([[silent exec "norm! \<C-Y>"]])
        end
      else
        -- Scroll the window if the current line is not within 'scrolloff'.
        if not (vim.fn.winline() <= vim.o.so + 1 or vim.fn.winline() >= vim.fn.winheight('%') - vim.o.so) then
          vim.cmd([[silent exec "norm! \<C-Y>"]])
        end
      end
    end
    counter = counter + 1
    require('cinnamon.utils').SleepDelay(-distance + counter, delay, slowdown)
  end
  -- Center the screen.
  require('cinnamon.utils').CenterScreen(0, scrollWin, delay, slowdown)
end

local function LspFunctionWait(command)
  local originalTagStack = vim.fn.gettagstack()
  -- Call the lsp function.
  if command == 'declaration' then
    require('vim.lsp.buf').declaration()
  elseif command == 'definition' then
    require('vim.lsp.buf').definition()
  end
  -- The tagstack is still pushed even if the location isn't being changed so monitor it.
  local counter = 0
  while true do
    -- Break if the tagstack changes.
    if vim.fn.gettagstack() ~= originalTagStack then
      -- The tagstack is set before location is changed so use a delay before getting location.
      vim.cmd('sleep 100m')
      break
    end
    -- Break if the count gets too high.
    if counter > 500 then
      break
    end
    counter = counter + 1
  end
end

function M.GetScrollDistance(command, useCount)
  local newColumn = -1
  -- Create a backup for the current window view.
  local viewSaved = vim.fn.winsaveview()
  -- Calculate distance by subtracting the original position from the new
  -- position after performing the command.
  local row = vim.fn.getcurpos()[2]
  local curswant = vim.fn.getcurpos()[5]
  local prevFile = vim.fn.getreg('%')
  -- Perform the command.
  if command == 'definition' or command == 'declaration' then
    LspFunctionWait(command)
    -- elseif command:sub(1, 1) == ':' then
    --   vim.cmd(command:sub(2))
    --   vim.cmd('sleep 100m')
  elseif useCount ~= 0 and vim.v.count1 > 1 then
    vim.cmd('norm! ' .. vim.v.count1 .. command)
  else
    vim.cmd('norm! ' .. command)
  end
  -- If searching within a fold, open the fold.
  for _, item in pairs { 'n', 'N', '*', '#', 'g*', 'g#' } do
    if command == item and vim.fn.foldclosed('.') ~= -1 then
      vim.cmd('norm! zo')
    end
  end
  local newRow = vim.fn.getcurpos()[2]
  local newFile = vim.fn.getreg('%')
  -- Check if the file has changed.
  if prevFile ~= newFile then
    -- Center the screen.
    vim.cmd('norm! zz')
    return 0, -1, true, false
  end
  -- Calculate the movement distance.
  local distance = newRow - row
  -- Check if the distance is too long.
  local scrollLimit = vim.g.__cinnamon_scroll_limit
  if distance > scrollLimit or distance < -scrollLimit then
    return 0, -1, false, true
  end
  -- Get the new column position if 'curswant' has changed.
  if curswant ~= vim.fn.getcurpos()[5] then
    newColumn = vim.fn.getcurpos()[3]
  end
  -- Restore the window view.
  vim.fn.winrestview(viewSaved)
  return distance, newColumn, false, false
end

function M.SleepDelay(remaining, delay, slowdown)
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

function M.CenterScreen(remaining, scrollWin, delay, slowdown)
  local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
  if scrollWin == 1 and vim.g.__cinnamon_centered == true then
    local prevLine = vim.fn.winline()
    while vim.fn.winline() > halfHeight do
      vim.cmd([[silent exec "norm! \<C-E>"]])
      local newLine = vim.fn.winline()
      require('cinnamon.utils').SleepDelay(newLine - halfHeight + remaining, delay, slowdown)
      -- If line isn't changing, break the endless loop.
      if newLine == prevLine then
        break
      end
      prevLine = newLine
    end
    while vim.fn.winline() < halfHeight do
      vim.cmd([[silent exec "norm! \<C-Y>"]])
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
