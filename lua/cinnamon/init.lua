-- TODO: Create the functions here in lua

function Scroll(movement, scrollWin, useCount, delay, slowdown, maxLines)
  if (movement == "j" or movement == "k") and vim.v.count1 == 1 then
    vim.cmd("norm! " .. movement)
    return
  end
end

function CheckFold(counter)
  local foldStart = vim.fn.foldclosed(".")
  -- If a fold exists, add the length to the counter.
  if foldStart ~= -1 then
    local foldSize = vim.fn.foldclosedend(foldStart) - foldStart
    counter = counter + foldSize
  end
  return counter
end

function MovementDistance(movement, useCount)
  local viewSaved = vim.fn.winsaveview()
  local row = vim.fn.getcurpos()[2]
  local curswant = vim.fn.getcurpos()[5]
  local file = vim.fn.bufname("%")
  if useCount == 1 and vim.v.count1 > 1 then
    vim.cmd("norm! " .. vim.v.count1 .. movement)
  else
    vim.cmd("norm! " .. movement)
  end
  local newRow = vim.fn.getcurpos()[2]
  local newFile = vim.fn.bufname("%")
end

-- function! s:Scroll(movement, scrollWin = '1', useCount = '0', delay = '5', slowdown = '1', maxLines = '300') abort
--     " Don't waste time performing the whole function if only moving one line.
--     if a:movement == 'j' && v:count1 == 1
--         silent execute("normal! j")
--         return
--     elseif a:movement == 'k' && v:count1 == 1
--         silent execute("normal! k")
--         return
--     endif
--     " Save the last used arguments in a variable for vim-repeat.
--     if !exists("g:cinnamon_repeat") | let g:cinnamon_repeat = 1 | endif
--     if g:cinnamon_repeat == 1
--         let b:cinnamonArgs = '"'.a:movement.'","'.a:scrollWin.'","'.a:useCount.'","'.a:delay.'","'.a:slowdown.'","'.a:maxLines.'"'
--         let b:cinnamonCount = v:count1
--     endif
--     " Get the scroll distance and the column position.
--     let measurments = <SID>MovementDistance(a:movement, a:useCount)
--     let l:distance = measurments[0]
--     let l:newColumn = measurments[1]
--     if l:distance == 0
--         " Set vim-repeat.
--         if g:cinnamon_repeat == 1
--             silent! call repeat#set("\<Plug>CinnamonRepeat",b:cinnamonCount)
--         endif
--         return
--     endif
--     " If scrolling distance is too great, just perform the movement without scroll.
--     if l:distance > a:maxLines || l:distance < -a:maxLines
--         if a:useCount == 1
--             silent execute("normal! " . v:count1 . a:movement)
--         else
--             silent execute("normal! " . a:movement)
--         endif
--         " Set vim-repeat.
--         if g:cinnamon_repeat == 1
--             silent! call repeat#set("\<Plug>CinnamonRepeat",b:cinnamonCount)
--         endif
--         return
--     endif
--     let l:counter = 1
--     if distance > 0
--         " Scrolling downwards.
--         while l:counter <= l:distance
--             " Check if a fold exists at current line.
--             let l:counter = <SID>CheckFold(l:counter)
--             " Move down by one line.
--             silent execute("normal! j")
--             if a:scrollWin == 1
--                 " Scroll the window if the current line is not within the scrolloff borders.
--                 if ! (winline() <= &scrolloff + 1 || winline() >= winheight('%') - &scrolloff)
--                     silent execute("normal! \<C-E>")
--                 endif
--             endif
--             let l:counter += 1
--             let l:remaining = l:distance - l:counter
--             call <SID>SleepDelay(l:remaining, a:delay, a:slowdown)
--         endwhile
--     else
--         " Scrolling upwards.
--         while l:counter <= -l:distance
--             " Check if a fold exists at current line.
--             let l:counter = <SID>CheckFold(l:counter)
--             " Move up by one line.
--             silent execute("normal! k")
--             if a:scrollWin == 1
--                 " Scroll the window if the current line is not within the scrolloff borders.
--                 if ! (winline() <= &scrolloff + 1 || winline() >= winheight('%') - &scrolloff)
--                     silent execute("normal! \<C-Y>")
--                 endif
--             endif
--             let l:counter += 1
--             let l:remaining = - (l:distance + l:counter)
--             call <SID>SleepDelay(l:remaining, a:delay, a:slowdown)
--         endwhile
--     endif
--     " Change the cursor column position.
--     if l:newColumn != -1 | call cursor(line("."), l:newColumn) | endif
--     " Set vim-repeat.
--     if g:cinnamon_repeat == 1
--         silent! call repeat#set("\<Plug>CinnamonRepeat",b:cinnamonCount)
--     endif
-- endfunction

-- function! s:CheckFold(counter)
--     let l:counter = a:counter
--     let l:foldStart = foldclosed(".")
--     " If a fold exists, add the length to the counter.
--     if l:foldStart != -1
--         " Calculate the fold size.
--         let l:foldSize = foldclosedend(l:foldStart) - l:foldStart
--         let l:counter += l:foldSize
--     endif
--     return l:counter
-- endfunction

-- function! s:MovementDistance(movement, useCount)
--     " Create a backup for the current window view.
--     let l:winview = winsaveview()
--     " Calculate distance by subtracting the original position from the position
--     " after performing the movement.
--     let l:row = getcurpos()[1]
--     let l:curswant = getcurpos()[4]
--     let l:file = bufname("%")
--     if a:useCount == 1
--         silent execute("normal! " . v:count1 . a:movement)
--     else
--         silent execute("normal! " . a:movement)
--     endif
--     let l:newRow = getcurpos()[1]
--     let l:newFile = bufname("%")
--     " Check if the file has changed.
--     if l:file != l:newFile
--         let l:distance = 0
--         return
--     endif
--     let l:distance = l:newRow - l:row
--     " Get the column position if 'curswant' has changed.
--     if l:curswant == getcurpos()[4]
--         let l:newColumn = -1
--     else
--         let l:newColumn = getcurpos()[2]
--     endif
--     " Restore the window view.
--     call winrestview(l:winview)
--     " Return a list of the values.
--     let measurements = [l:distance,l:newColumn]
--     return measurements
-- endfunction
