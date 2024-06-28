local M = {}

local defaults = {
    disabled = false,
    keymaps = {
        basic = true,
        extra = false,
    },
    options = {
        callback = nil,
        delay = 7,
        max_delta = {
            line = 150,
            column = 200,
        },
        mode = "cursor", ---@type "cursor" | "window"
    },
}

local deprecated = {
    ["default_keymaps"] = "The 'default_keymaps' option has been deprecated. Use 'keymaps.basic'.",
    ["extra_keymaps"] = "The 'extra_keymaps' option has beeen deprecated. Use 'keymaps.basic' and/or 'keymaps.extra'.",
    ["extended_keymaps"] = "The 'extended_keymaps' option has been deprecated. Use 'keymaps.extra'.",
    ["override_keymaps"] = "The 'override_keymaps' option has been removed.",
    ["always_scroll"] = "The 'always_scroll' option has been deprecated. Use 'options.mode == \"screen\"'.",
    ["centered"] = "The 'centered' option has been deprecated. Append 'zz' to your command to replicate.",
    ["default_delay"] = "The 'default_delay' option has been deprecated. Use 'options.delay'.",
    ["hide_cursor"] = "The 'hide_cursor' option has been removed. The cursor is hidden when using 'options.mode = \"screen\".",
    ["horizontal_scroll"] = "The 'horizontal_scroll' option has been removed. Horizontal scrolling is always enabled.",
    ["max_length"] = "The 'max_length' option has been deprecated. Use 'options.max_delta'.",
    ["scroll_limit"] = "The 'scroll_limit' option has been deprecated. Use 'options.max_delta'.",
}

local config = {}

M.get = function()
    return config
end

function M.setup(user_config)
    user_config = user_config or {}

    -- Check for deprecated options.
    for option, message in pairs(deprecated) do
        local keys = vim.split(option, ".", { plain = true })
        if vim.tbl_get(user_config, unpack(keys)) ~= nil then
            vim.notify("[cinnamon.config] " .. message, vim.log.levels.WARN)
        end
    end

    -- Convert deprecated options to new options.
    if user_config.default_keymaps ~= nil then
        user_config.keymaps = {
            basic = user_config.default_keymaps,
        }
    end
    if user_config.extra_keymaps ~= nil then
        user_config.keymaps = {
            basic = user_config.extra_keymaps,
            extra = user_config.extra_keymaps,
        }
    end
    if user_config.extended_keymaps == true then
        user_config.keymaps = {
            extra = true,
        }
    end
    if user_config.default_delay ~= nil then
        user_config.options = {
            delay = user_config.default_delay,
        }
    end
    if user_config.scroll_limit ~= nil then
        user_config.options = {
            max_delta = {
                line = (user_config.scroll_limit <= 0) and 9999 or user_config.scroll_limit,
            },
        }
    end

    -- Merge user options with defaults.
    config = vim.tbl_deep_extend("force", {}, defaults, user_config)
end

return M
