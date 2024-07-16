local M = {}

---@param message string
---@param level "debug" | "error" | "info" | "trace" | "warn" | "off"
---@param options? table={once: boolean?, schedule: boolean?}
M.notify = function(message, level, options)
    options = options or {}
    local notify_level = vim.log.levels[level:upper()]
    assert(notify_level, "Invalid log level: " .. level)
    local notify_fn = options.once and vim.notify_once or vim.notify
    if options.schedule then
        notify_fn = vim.schedule_wrap(notify_fn)
    end
    notify_fn("[cinnamon.nvim] " .. message, notify_level)
end

---@param str string
---@return string
M.keycode = vim.keycode or function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

M.uv = vim.uv or vim.loop

return M
