local M = {}

---@class CinnamonNotifyOptions
---@field level "debug" | "error" | "info" | "trace" | "warn" | "off"
---@field once boolean?
---@field schedule boolean?

---@param message string
---@param options CinnamonNotifyOptions
M.notify = function(message, options)
    local level = vim.log.levels[options.level:upper()]
    assert(level, "Invalid log level: " .. options.level)
    local notify_fn = options.once and vim.notify_once or vim.notify
    if options.schedule then
        notify_fn = vim.schedule_wrap(notify_fn)
    end
    notify_fn("[cinnamon.nvim] " .. message, level)
end

return M
