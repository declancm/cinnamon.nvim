" Make sure the plugin is only loaded once.
if exists("g:loaded_cinnamon")
    finish
endif
let g:loaded_cinnamon = 1

" FUNCTIONS:

function! s:Scroll(movement, scrollWin = '1', useCount = '0', delay = '5',
            \ slowdown = '1', maxLines = '150') abort
    " Don't waste time performing the whole function if only moving one line.
    if (a:movement == 'k' || a:movement == 'j') && v:count1 == 1
        silent exec "norm! " . a:movement
        return
    endif
    " Save the last used arguments in a variable for vim-repeat.
    if !exists("g:cinnamon_repeat") | let g:cinnamon_repeat = 1 | endif
    if g:cinnamon_repeat == 1
        let b:cinnamonArgs = '"'.a:movement.'","'.a:scrollWin.'","'.a:useCount
                    \.'","'.a:delay.'","'.a:slowdown.'","'.a:maxLines.'"'
        let b:cinnamonCount = v:count1
    endif
    " Get the scroll distance and the column position.
    let measurments = <SID>MovementDistance(a:movement, a:useCount)
    let l:distance = measurments[0]
    let l:newColumn = measurments[1]
    " If there is no vertical movement, return.
    if l:distance == 0
        " center the screen if it's not centered.
        if a:scrollWin == 1 && exists("g:cinnamon_centered") && g:cinnamon_centered == 1
            normal! zz
        endif
        " Change the cursor column position if required.
        if l:newColumn != -1 | call cursor(line("."), l:newColumn) | endif
        " Set vim-repeat.
        if g:cinnamon_repeat == 1
            silent! call repeat#set("\<Plug>CinnamonRepeat",b:cinnamonCount)
        endif
        return
    endif
    " If the distance is too long, perform the movement without the scroll.
    if l:distance > a:maxLines || l:distance < -a:maxLines
        if a:useCount == 1 && v:count1 > 1
            silent exec "norm! " . v:count1 . a:movement
        else
            silent exec "norm! " . a:movement
        endif
        " Set vim-repeat.
        if g:cinnamon_repeat == 1
            silent! call repeat#set("\<Plug>CinnamonRepeat",b:cinnamonCount)
        endif
        return
    endif
    " Perform the scroll.
    if l:distance > 0
        call <SID>ScrollDown(l:distance, a:delay, a:scrollWin, a:slowdown)
    else
        call <SID>ScrollUp(l:distance, a:delay, a:scrollWin, a:slowdown)
    endif
    " center the screen if it's not centered.
    call <sid>CenterScreen(0, a:scrollWin, a:delay, a:slowdown)
    " Change the cursor column position if required.
    if l:newColumn != -1 | call cursor(line("."), l:newColumn) | endif
    " Set vim-repeat.
    if g:cinnamon_repeat == 1
        silent! call repeat#set("\<Plug>CinnamonRepeat",b:cinnamonCount)
    endif
endfunction

function! s:ScrollDown(distance, delay, scrollWin, slowdown)
    let l:halfHeight = (winheight(0) % 2) ? ((winheight(0) + 1)/2) : (winheight(0)/2)
    if winline() > l:halfHeight
        call <sid>CenterScreen(a:distance, a:scrollWin, a:delay, a:slowdown)
    endif
    let l:counter = 1
    while l:counter <= a:distance
        let l:counter = <SID>CheckFold(l:counter)
        silent exec "norm! j"
        if a:scrollWin == 1
            if exists("g:cinnamon_centered") && g:cinnamon_centered == 1
                " Stay at the centre of the screen.
                if winline() > l:halfHeight | silent exec "norm! \<C-E>" | endif
            else
                " Scroll the window if the current line is not within the
                " scrolloff borders.
                if ! (winline() <= &so + 1 || winline() >= winheight('%') - &so)
                    silent exec "norm! \<C-E>"
                endif
            endif
        endif
        let l:counter += 1
        call <SID>SleepDelay(a:distance - l:counter, a:delay, a:slowdown)
    endwhile
endfunction

function! s:ScrollUp(distance, delay, scrollWin, slowdown)
    let l:halfHeight = (winheight(0) % 2) ? ((winheight(0) + 1)/2) : (winheight(0)/2)
    if winline() < l:halfHeight
        call <sid>CenterScreen(-(a:distance), a:scrollWin, a:delay, a:slowdown)
    endif
    let l:counter = 1
    while l:counter <= -a:distance
        let l:counter = <SID>CheckFold(l:counter)
        silent exec "norm! k"
        if a:scrollWin == 1
            if exists("g:cinnamon_centered") && g:cinnamon_centered == 1
                " Stay at the centre of the screen.
                if winline() < l:halfHeight | silent exec "norm! \<C-Y>" | endif
            else
                " Scroll the window if the current line is not within the
                " scrolloff borders.
                if ! (winline() <= &so + 1 || winline() >= winheight('%') - &so)
                    silent exec "norm! \<C-Y>"
                endif
            endif
        endif
        let l:counter += 1
        call <SID>SleepDelay(-(a:distance + l:counter), a:delay, a:slowdown)
    endwhile
endfunction

function! s:CheckFold(counter)
    let l:counter = a:counter
    let l:foldStart = foldclosed(".")
    " If a fold exists, add the length to the counter.
    if l:foldStart != -1
        let l:foldSize = foldclosedend(l:foldStart) - l:foldStart
        let l:counter += l:foldSize
    endif
    return l:counter
endfunction

function! s:MovementDistance(movement, useCount)
    " Create a backup for the current window view.
    let l:winview = winsaveview()
    " Calculate distance by subtracting the original position from the position
    " after performing the movement.
    let l:row = getcurpos()[1]
    let l:curswant = getcurpos()[4]
    let l:file = bufname("%")
    if a:useCount == 1 && v:count1 > 1
        silent exec "norm! " . v:count1 . a:movement
    else
        silent exec "norm! " . a:movement
    endif
    let l:newRow = getcurpos()[1]
    let l:newFile = bufname("%")
    " Check if the file has changed.
    if l:file != l:newFile
        " Center the screen.
        normal! zz
        let l:distance = 0
        return
    endif
    let l:distance = l:newRow - l:row
    " Get the new column position if 'curswant' has changed.
    if l:curswant == getcurpos()[4]
        let l:newColumn = -1
    else
        let l:newColumn = getcurpos()[2]
    endif
    " Restore the window view.
    call winrestview(l:winview)
    let measurements = [l:distance,l:newColumn]
    return measurements
endfunction

function! s:SleepDelay(remaining, delay, slowdown)
    redraw
    if a:slowdown == 1
        " Don't create a delay when scrolling completed.
        if a:remaining <= 0
            redraw
            return
        endif
        " Increase the delay near the end of the scroll.
        if a:remaining <= 4
            silent exec "sleep " . (a:delay * (5 - a:remaining)) . "m"
        else
            silent exec "sleep " . a:delay . "m"
        endif
    else
        silent exec "sleep " . a:delay . "m"
    endif
endfunction

function! s:CenterScreen(remaining, scrollWin, delay, slowdown)
    let l:halfHeight = (winheight(0) % 2) ? ((winheight(0) + 1)/2) : (winheight(0)/2)
    if a:scrollWin == 1 && exists("g:cinnamon_centered") && g:cinnamon_centered == 1
        let l:prevLine = winline()
        while winline() > l:halfHeight
            silent exec "norm! \<C-E>"
            let l:newLine = winline()
            call <SID>SleepDelay(l:newLine - l:halfHeight + a:remaining, a:delay,
                        \ a:slowdown)
            " If line isn't changing, break the endless loop.
            if l:newLine == l:prevLine | break | endif
            let l:prevLine = l:newLine
        endwhile
        while winline() < l:halfHeight
            silent exec "norm! \<C-Y>"
            let l:newLine = winline()
            call <SID>SleepDelay(l:halfHeight - l:newLine + a:remaining, a:delay,
                        \ a:slowdown)
            " If line isn't changing, break the endless loop.
            if l:newLine == l:prevLine | break | endif
            let l:prevLine = l:newLine
        endwhile
    endif
endfunction

" COMMAND:

" <Cmd>Cinnamon arg1 arg2 arg3 arg4 arg5 arg6 <CR>

" arg1 = Movement command (eg. 'gg'). This argument is required as there's no
"        default value.
" arg2 = Keep cursor centered in the window. (1 for on, 0 for off). Default is 1.
" arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
" arg4 = Length of delay (in ms). Default is 5.
" arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.
" TODO: make arg6 into a variable instead?
" arg6 = Max number of lines before scrolling is skipped. Mainly just for big
"        commands such as 'gg' and 'G'. Default is 150.

command! -nargs=+ Cinnamon call <SID>Scroll(<f-args>)

" KEYMAPS:

" Keymap for vim-repeat
nnoremap <silent> <Plug>CinnamonRepeat
            \ <Cmd>silent exec "call <SID>Scroll(" . b:cinnamonArgs . ")"<CR>

" Setting the center window variable.
if !exists("g:cinnamon_centered")
    let g:cinnamon_centered = 1
endif

" Initializing defualt keymaps.
if !exists("g:cinnamon_no_defaults")
    let g:cinnamon_no_defaults = 0
endif
if g:cinnamon_no_defaults != 1
    " Half-window movements.
    noremap <silent> <C-u> <Cmd>Cinnamon <C-u> <CR>
    noremap <silent> <C-d> <Cmd>Cinnamon <C-d> <CR>
    inoremap <silent> <C-u> <Cmd>Cinnamon <C-u> <CR>
    inoremap <silent> <C-d> <Cmd>Cinnamon <C-d> <CR>

    " Page movements.
    nnoremap <silent> <C-b> <Cmd>Cinnamon <C-b> 1 1 <CR>
    nnoremap <silent> <C-f> <Cmd>Cinnamon <C-f> 1 1 <CR>
    nnoremap <silent> <PageUp> <Cmd>Cinnamon <C-b> 1 1 <CR>
    nnoremap <silent> <PageDown> <Cmd>Cinnamon <C-f> 1 1 <CR>

    " Paragraph movements.
    nnoremap <silent> { <Cmd>Cinnamon { 0 <CR>
    nnoremap <silent> } <Cmd>Cinnamon } 0 <CR>
    xnoremap <silent> { <Cmd>Cinnamon { 0 <CR>
    xnoremap <silent> } <Cmd>Cinnamon } 0 <CR>

    " Previous/next search result.
    nnoremap <silent> n <Cmd>Cinnamon n 1 0 3 <CR>
    nnoremap <silent> N <Cmd>Cinnamon N 1 0 3 <CR>
    nnoremap <silent> * <Cmd>Cinnamon * 1 0 3 <CR>
    nnoremap <silent> # <Cmd>Cinnamon # 1 0 3 <CR>

    " Previous cursor location.
    nnoremap <silent> <C-o> <Cmd>Cinnamon <C-o> 1 0 3 <CR>

    " TODO: get <Tab> to work with the command.
    " nnoremap <silent> <C-i> <Cmd>Cinnamon <C-i> 1 0 3 <CR>
endif

" Initializing extra keymaps.
if !exists("g:cinnamon_extras")
    let g:cinnamon_extras = 0
endif
if g:cinnamon_extras == 1
    " Start and end of file movements.
    nnoremap <silent> gg <Cmd>Cinnamon gg 0 0 3 <CR>
    nnoremap <silent> G <Cmd>Cinnamon G 0 0 3 <CR>
    xnoremap <silent> gg <Cmd>Cinnamon gg 0 0 3 <CR>
    xnoremap <silent> G <Cmd>Cinnamon G 0 0 3 <CR>

    " Up and down movements which accepts a count (eg. 69j to scroll down 69
    " lines).
    nnoremap <silent> k <Cmd>Cinnamon k 0 1 2 0 <CR>
    nnoremap <silent> j <Cmd>Cinnamon j 0 1 2 0 <CR>
    nnoremap <silent> <Up> <Cmd>Cinnamon k 0 1 2 0 <CR>
    nnoremap <silent> <Down> <Cmd>Cinnamon j 0 1 2 0 <CR>
    xnoremap <silent> k <Cmd>Cinnamon k 0 1 2 0 <CR>
    xnoremap <silent> j <Cmd>Cinnamon j 0 1 2 0 <CR>
    xnoremap <silent> <Up> <Cmd>Cinnamon k 0 1 2 0 <CR>
    xnoremap <silent> <Down> <Cmd>Cinnamon j 0 1 2 0 <CR>
endif
