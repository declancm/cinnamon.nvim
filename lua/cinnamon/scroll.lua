local M = {}

-- TODO: get n and N to work well with folds.
-- TODO: display a better error message if search not found.
-- Create an array of all the search movements and check the value of @/ ?
-- TODO: make it work for g commands such as gj and gk.

--[[

require('cinnamon.scroll').Scroll('arg1', 'arg2', 'arg3', 'arg4', 'arg5', 'arg6')

arg1 = The movement command (eg. 'gg'). This argument is required as there's\
no default value.
arg2 = Scroll the window with the cursor. (1 for on, 0 for off). Default is 1.
arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
arg4 = Length of delay between lines (in ms). Default is 5.
arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.

Note: Each argument is a string separated by a comma.

]]

function M.Scroll(movement, scrollWin, useCount, delay, slowdown)
  -- Setting defaults:
  scrollWin = scrollWin or 1
  useCount = useCount or 0
  delay = delay or 5
  slowdown = slowdown or 1
  local maxLines = vim.g.__cinnamon_scroll_limit
  -- Don't waste time performing the whole function if only moving one line.
  for _, item in pairs { 'j', 'k' } do
    if item == movement and vim.v.count1 == 1 then
      vim.cmd('norm! ' .. movement)
      return
    end
  end
  -- If no search pattern, return an error if using a search movement.
  for _, command in pairs { 'n', 'N' } do
    if command == movement then
      if vim.fn.getreg '/' == '' then
        vim.cmd [[echohl ErrorMsg | echo "Cinnamon: The search pattern is empty." | echohl None]]
        return
      end
      if vim.fn.search(vim.fn.getreg '/', 'nw') == 0 then
        vim.cmd [[echohl ErrorMsg | echo "Cinnamon: Pattern not found: " . getreg('/') | echohl None ]] -- E486
        return
      end
    end
  end
  -- If no word under cursor, return an error if using a search movement.
  for _, command in pairs { '*', '#', 'g*', 'g#' } do
    if command == movement then
      -- Check if string is empty or only whitespace.
      if vim.fn.getline('.'):match '^%s*$' then
        vim.cmd [[echohl ErrorMsg | echo "Cinnamon: No string under cursor." | echohl None]] -- E348
        return
      end
    end
  end
  -- Get the scroll distance and the column position.
  local distance, newColumn, fileChanged = require('cinnamon.utils').MovementDistance(movement, useCount)
  -- It the distance is too long, perform the movement without the scroll.
  if distance > maxLines or distance < -maxLines then
    if useCount ~= 0 and vim.v.count1 > 1 then
      vim.cmd('norm! ' .. vim.v.count1 .. movement)
    else
      vim.cmd('norm! ' .. movement)
    end
    return
  end
  -- Perform the scroll.
  if distance > 0 then
    require('cinnamon.utils').ScrollDown(distance, delay, scrollWin, slowdown)
  elseif distance < 0 then
    require('cinnamon.utils').ScrollUp(distance, delay, scrollWin, slowdown)
  end
  -- Center the screen if it's not centered.
  if fileChanged == false then
    require('cinnamon.utils').CenterScreen(0, scrollWin, delay, slowdown)
  end
  -- Change the cursor column position if required.
  if newColumn ~= -1 then
    vim.fn.cursor(vim.fn.line '.', newColumn)
  end
end

return M
