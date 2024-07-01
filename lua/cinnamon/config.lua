local utils = require("cinnamon.utils")
local M = {}

---@class CinnamonOptions
local defaults = {
    disabled = false, ---@type boolean
    keymaps = {
        basic = false, ---@type boolean
        extra = false, ---@type boolean
    },
    ---@class ScrollOptions
    options = {
        callback = nil, ---@type function?
        delay = 7, ---@type number
        max_delta = {
            line = nil, ---@type number?
            column = nil, ---@type number?
            time = 1000, ---@type number
        },
        mode = "cursor", ---@type "cursor" | "window"
    },
}

local deprecated = {
    ["default_keymaps"] = "The 'default_keymaps' option has been deprecated. Please use 'keymaps.basic' instead",
    ["extra_keymaps"] = "The 'extra_keymaps' option has beeen deprecated. Please use 'keymaps.extra' instead",
    ["extended_keymaps"] = "The 'extended_keymaps' option has been deprecated. Please use 'keymaps.extra' instead",
    ["override_keymaps"] = "The 'override_keymaps' option has been removed",
    ["always_scroll"] = "The 'always_scroll' option has been deprecated. Please use 'options.mode' instead",
    ["centered"] = "The 'centered' option has been deprecated. Append 'zz' to your command to replicate",
    ["default_delay"] = "The 'default_delay' option has been deprecated. Please use 'options.delay' instead",
    ["hide_cursor"] = "The 'hide_cursor' option has been removed. The cursor is hidden when using 'options.mode = \"window\"",
    ["horizontal_scroll"] = "The 'horizontal_scroll' option has been removed. Horizontal scrolling is always enabled",
    ["max_length"] = "The 'max_length' option has been deprecated. Please use 'options.max_delta.time' instead",
    ["scroll_limit"] = "The 'scroll_limit' option has been deprecated. Please use 'options.max_delta.line' instead",
}

---@type CinnamonOptions
local config = {}

---@return CinnamonOptions
M.get = function()
    return config
end

function M.setup(user_config)
    user_config = user_config or {}

    -- Check for deprecated options.
    for option, message in pairs(deprecated) do
        local keys = vim.split(option, ".", { plain = true })
        if vim.tbl_get(user_config, unpack(keys)) ~= nil then
            utils.notify(message, "warn")
        end
    end

    -- Convert deprecated options to new options.
    user_config.keymaps = user_config.keymaps or {}
    user_config.keymaps.basic = user_config.keymaps.basic or user_config.default_keymaps or user_config.extra_keymaps
    user_config.keymaps.extra = user_config.keymaps.extra or user_config.extra_keymaps or user_config.extended_keymaps

    user_config.options = user_config.options or {}
    user_config.options.delay = user_config.options.delay or user_config.default_delay
    user_config.options.max_delta = user_config.options.max_delta or {}
    if user_config.scroll_limit ~= nil then
        if user_config.scroll_limit < 0 then
            user_config.options.max_delta.line = 9999
        else
            user_config.options.max_delta.line = user_config.scroll_limit
        end
    end

    -- Merge user options with defaults.
    config = vim.tbl_deep_extend("force", {}, defaults, user_config)
end

return M
