" Make sure the plugin is only loaded once.
if exists("g:loaded_cinnamon")
    finish
endif
let g:loaded_cinnamon = 1

" FUNCTIONS:

function! s:Scroll(movement, scrollWin = '1', useCount = '0', delay = '5', slowdown = '1', maxLines = '300') abort
    " Don't waste time performing the whole function if only moving one line.
    if a:movement == 'j' && v:count1 == 1
        silent execute("normal! j")
        return
    elseif a:movement == 'k' && v:count1 == 1
        silent execute("normal! k")
        return
    endif
    " Save the last used arguments in a variable for vim-repeat.
    if !exists("g:cinnamon_repeat") | let g:cinnamon_repeat = 1 | endif
    if g:cinnamon_repeat == 1
        let b:cinnamonArgs = '"'.a:movement.'","'.a:scrollWin.'","'.a:useCount.'","'.a:delay.'","'.a:slowdown.'","'.a:maxLines.'"'
        let b:cinnamonCount = v:count1
    endif
    " Get the scroll distance and the column position.
    let measurments = <SID>MovementDistance(a:movement, a:useCount)
    let l:distance = measurments[0]
    let l:newColumn = measurments[1]
    if l:distance == 0
        " Set vim-repeat.
        if g:cinnamon_repeat == 1
            silent! call repeat#set("\<Plug>CinnamonRepeat",b:cinnamonCount)
        endif
        return
    endif
    " If scrolling distance is too great, just perform the movement without scroll.
    if l:distance > a:maxLines || l:distance < -a:maxLines
        if a:useCount == 1
            silent execute("normal! " . v:count1 . a:movement)
        else
            silent execute("normal! " . a:movement)
        endif
        " Set vim-repeat.
        if g:cinnamon_repeat == 1
            silent! call repeat#set("\<Plug>CinnamonRepeat",b:cinnamonCount)
        endif
        return
    endif
    let l:counter = 1
    if distance > 0
        " Scrolling downwards.
        while l:counter <= l:distance
            " Check if a fold exists at current line.
            let l:counter = <SID>CheckFold(l:counter)
            " Move down by one line.
            silent execute("normal! j")
            if a:scrollWin == 1
                " Scroll the window if the current line is not within the scrolloff borders.
                if ! (winline() <= &scrolloff + 1 || winline() >= winheight('%') - &scrolloff)
                    silent execute("normal! \<C-E>")
                endif
            endif
            let l:counter += 1
            let l:remaining = l:distance - l:counter
            call <SID>SleepDelay(l:remaining, a:delay, a:slowdown)
        endwhile
    else
        " Scrolling upwards.
        while l:counter <= -l:distance
            " Check if a fold exists at current line.
            let l:counter = <SID>CheckFold(l:counter)
            " Move up by one line.
            silent execute("normal! k")
            if a:scrollWin == 1
                " Scroll the window if the current line is not within the scrolloff borders.
                if ! (winline() <= &scrolloff + 1 || winline() >= winheight('%') - &scrolloff)
                    silent execute("normal! \<C-Y>")
                endif
            endif
            let l:counter += 1
            let l:remaining = - (l:distance + l:counter)
            call <SID>SleepDelay(l:remaining, a:delay, a:slowdown)
        endwhile
    endif
    " Change the cursor column position.
    if l:newColumn != -1 | call cursor(line("."), l:newColumn) | endif
    " Set vim-repeat.
    if g:cinnamon_repeat == 1
        silent! call repeat#set("\<Plug>CinnamonRepeat",b:cinnamonCount)
    endif
endfunction

function! s:CheckFold(counter)
    let l:counter = a:counter
    let l:foldStart = foldclosed(".")
    " If a fold exists, add the length to the counter.
    if l:foldStart != -1
        " Calculate the fold size.
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
    if a:useCount == 1
        silent execute("normal! " . v:count1 . a:movement)
    else
        silent execute("normal! " . a:movement)
    endif
    let l:newRow = getcurpos()[1]
    let l:newFile = bufname("%")
    " Check if the file has changed.
    if l:file != l:newFile
        let l:distance = 0
        return
    endif
    let l:distance = l:newRow - l:row
    " Get the column position if 'curswant' has changed.
    if l:curswant == getcurpos()[4]
        let l:newColumn = -1
    else
        let l:newColumn = getcurpos()[2]
    endif
    " Restore the window view.
    call winrestview(l:winview)
    " Return a list of the values.
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
            silent execute("sleep " . (a:delay * (5 - a:remaining)) . "m")
        else
            silent execute("sleep " . a:delay . "m")
        endif
    else
        silent execute("sleep " . a:delay . "m")
    endif
endfunction

" COMMAND:

" <Cmd>Cinnamon arg1 arg2 arg3 arg4 arg5 arg6 <CR>

" arg1 = Movement command (eg. 'gg'). This argument is required as there's no default value.
" arg2 = Keep cursor centered in the window. (1 for on, 0 for off). Default is 1.
" arg3 = Accept a count before the command (1 for on, 0 for off). Default is 0.
" arg4 = Length of delay (in ms). Default is 5.
" arg5 = Slowdown at the end of the movement (1 for on, 0 for off). Default is 1.
" arg6 = Max number of lines before scrolling is skipped. Mainly just for big
"        commands such as 'gg' and 'G'. Default is 300.

command! -nargs=+ Cinnamon call <SID>Scroll(<f-args>)

" KEYMAPS:

" Keymap for vim-repeat
nnoremap <silent> <Plug>CinnamonRepeat <Cmd>silent execute("call <SID>Scroll(" . b:cinnamonArgs . ")")<CR>

" Initializing defualt keymaps.
if !exists("g:cinnamon_no_defaults")
    let g:cinnamon_no_defaults = 0
endif
if g:cinnamon_no_defaults != 1
    " Paragraph movements.
    nnoremap <silent> { <Cmd>Cinnamon { 0 <CR>
    nnoremap <silent> } <Cmd>Cinnamon } 0 <CR>
    xnoremap <silent> { <Cmd>Cinnamon { 0 <CR>
    xnoremap <silent> } <Cmd>Cinnamon } 0 <CR>

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

    " Previous and next cursor location movements.
    nnoremap <silent> <C-o> <Cmd>Cinnamon <C-o> 0 <CR>
    nnoremap <silent> <C-i> <Cmd>Cinnamon <C-i> 0 <CR>

    " Up and down movements which accepts a count (eg. 69j to scroll down 69 lines).
    nnoremap <silent> k <Cmd>Cinnamon k 0 1 2 0 <CR>
    nnoremap <silent> j <Cmd>Cinnamon j 0 1 2 0 <CR>
    nnoremap <silent> <Up> <Cmd>Cinnamon k 0 1 2 0 <CR>
    nnoremap <silent> <Down> <Cmd>Cinnamon j 0 1 2 0 <CR>
    xnoremap <silent> k <Cmd>Cinnamon k 0 1 2 0 <CR>
    xnoremap <silent> j <Cmd>Cinnamon j 0 1 2 0 <CR>
    xnoremap <silent> <Up> <Cmd>Cinnamon k 0 1 2 0 <CR>
    xnoremap <silent> <Down> <Cmd>Cinnamon j 0 1 2 0 <CR>
endif
