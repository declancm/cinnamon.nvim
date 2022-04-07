local F = {}

local config = require("cinnamon.config")
local U = require("cinnamon.utils")

function F.CheckCommandErrors(command)
    -- If no search pattern, return an error if using a repeat search command.
    for _, item in pairs {"n", "N"} do
        if item == command then
            local pattern = vim.fn.getreg("/")
            if pattern == "" then
                U.ErrorMsg("The search pattern is empty")
                return true
            end
            if vim.fn.search(pattern, "nw") == 0 then
                U.ErrorMsg("Pattern not found: " .. vim.fn.getreg("/"), "E486")
                return true
            end
        end
    end

    -- If no word under cursor, return an error if using a word-near-cursor search command.
    for _, item in pairs {"*", "#", "g*", "g#"} do
        if item == command then
            -- Check if string is empty or only whitespace.
            if vim.fn.getline("."):match("^%s*$") then
                U.ErrorMsg("No string under cursor", "E348")
                return true
            end
        end
    end

    -- If no word under cursor, return an error if using a goto command.
    for _, item in pairs {"gd", "gD", "1gd", "1gD"} do
        if item == command then
            -- Check if string is empty or only whitespace.
            if vim.fn.getline("."):match("^%s*$") then
                U.ErrorMsg("No identifier under cursor", "E349")
                return true
            end
        end
    end

    -- If no errors, return false.
    return false
end

local function CheckForFold(counter)
    local foldStart = vim.fn.foldclosed(".")
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
        vim.cmd("norm! j")
        if scrollWin == 1 then
            local screenLine = vim.fn.winline()
            if config.centered then
                if screenLine > halfHeight then
                    vim.cmd('silent exe "norm! \\<C-E>"')
                end
            else
                -- Scroll the window if the current line is not within 'scrolloff'.
                if not (screenLine <= vim.opt.so:get() + 1 or screenLine >= vim.fn.winheight("%") - vim.opt.so:get()) then
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
        vim.cmd("norm! k")
        if scrollWin == 1 then
            local screenLine = vim.fn.winline()
            if config.centered then
                if screenLine < halfHeight then
                    vim.cmd('silent exe "norm! \\<C-Y>"')
                end
            else
                -- Scroll the window if the current line is not within 'scrolloff'.
                if not (screenLine <= vim.opt.so:get() + 1 or screenLine >= vim.fn.winheight("%") - vim.opt.so:get()) then
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

function F.Scroll(command, delay, slowdown)
    local windowHeight = vim.api.nvim_win_get_height(0)
    local function up(lines)
        local counter = 0
        while counter < lines do
            vim.cmd('silent exe "norm! \\<C-E>"')
            counter = counter + 1
            F.Delay(counter, delay, slowdown)
        end
    end
    local function down(lines)
        local counter = 0
        while counter > lines do
            vim.cmd('silent exe "norm! \\<C-Y>"')
            counter = counter - 1
            F.Delay(-counter, delay, slowdown)
        end
    end
    local lines
    if command == "zz" then
        lines = vim.fn.winline() - math.floor(windowHeight / 2 + 1)
    elseif command == "zt" then
        lines = vim.fn.winline() - 3
    elseif command == "zb" then
        lines = -(windowHeight - vim.fn.winline() - 3)
    end
    if lines > 0 then
        up(lines)
    elseif lines < 0 then
        down(lines)
    end
end

function F.GetScrollDistance(command, useCount)
    local savedView = vim.fn.winsaveview()

    local _, prevRow, _, _, prevCurswant = unpack(vim.fn.getcurpos())
    local prevFile = vim.fn.getreg("%")

    -- Perform the command.
    if command == "definition" then
        require("vim.lsp.buf").definition()
        vim.cmd("sleep 100m")
    elseif command == "declaration" then
        require("vim.lsp.buf").declaration()
        vim.cmd("sleep 100m")
    elseif useCount ~= 0 and vim.v.count > 0 then
        vim.cmd("norm! " .. vim.v.count .. command)
    else
        vim.cmd("norm! " .. command)
    end

    -- If searching within a fold, open the fold.
    local searchCommands = {
        "n",
        "N",
        "*",
        "#",
        "g*",
        "g#",
        "gd",
        "gD",
        "1gd",
        "1gD",
        "definition",
        "declaration"
    }
    for _, item in pairs(searchCommands) do
        if command == item and vim.fn.foldclosed(".") ~= -1 then
            vim.cmd("norm! zo")
        end
    end

    local _, newRow, newColumn, _, newCurswant = unpack(vim.fn.getcurpos())

    -- Check if the file has changed.
    if prevFile ~= vim.fn.getreg("%") then
        vim.cmd("norm! zz")
        return 0, -1, true, false
    end

    local distance = newRow - prevRow

    -- Check if scroll limit has been exceeded.
    if distance > config.scroll_limit or distance < -config.scroll_limit then
        return 0, -1, false, true
    end

    -- Check if curswant has changed.
    if prevCurswant == newCurswant then
        newColumn = -1
    end

    -- Restore the view to before the command was executed.
    vim.fn.winrestview(savedView)
    return distance, newColumn, false, false
end

function F.Delay(remaining, delay, slowdown)
    vim.cmd("redraw")

    -- Don't create a delay when scrolling comleted.
    if remaining <= 0 then
        return
    end

    -- Increase the delay near the end of the scroll.
    if remaining <= 4 and slowdown == 1 then
        vim.cmd("sleep " .. delay * (5 - remaining) .. "m")
    else
        vim.cmd("sleep " .. delay .. "m")
    end
end

function F.CenterScreen(remaining, scrollWin, delay, slowdown)
    local halfHeight = math.ceil(vim.fn.winheight(0) / 2)
    if scrollWin == 1 and config.centered then
        local prevLine = vim.fn.winline()

        -- Scroll up the screen.
        while vim.fn.winline() > halfHeight do
            vim.cmd('silent exe "norm! \\<C-E>"')
            local newLine = vim.fn.winline()
            F.Delay(newLine - halfHeight + remaining, delay, slowdown)
            if newLine == prevLine then
                break
            end
            prevLine = newLine
        end

        -- Scroll down the screen.
        while vim.fn.winline() < halfHeight do
            vim.cmd('silent exe "norm! \\<C-Y>"')
            local newLine = vim.fn.winline()
            F.Delay(halfHeight - newLine + remaining, delay, slowdown)
            if newLine == prevLine then
                break
            end
            prevLine = newLine
        end
    end
end

return F
