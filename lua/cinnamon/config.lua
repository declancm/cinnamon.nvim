local M = {}

M.config = {
    disabled = false,
    keymaps = {
        basic = true,
        extra = false,
    },
    options = {
        callback = nil,
        delay = 5,
        max_delta = {
            line = 150,
            column = 200,
        },
    },
}

local deprecated = {
    ["default_keymaps"] = "The 'default_keymaps' option has been deprecated. Use 'keymaps.basic'.",
    ["extra_keymaps"] = "The 'extra_keymaps' option has beeen deprecated. Use 'keymaps.basic' and/or 'keymaps.extra'.",
    ["extended_keymaps"] = "The 'extended_keymaps' option has been deprecated. Use 'keymaps.extra'.",
    ["override_keymaps"] = "The 'override_keymaps' option has been removed.",
    ["always_scroll"] = "The 'always_scroll' option has been removed. The cursor is always scrolled.",
    ["centered"] = "The 'centered' option has been deprecated. Append 'zz' to your command to replicate.",
    ["default_delay"] = "The 'default_delay' option has been deprecated. Use 'options.delay'.",
    ["hide_cursor"] = "The 'hide_cursor' option has been removed.",
    ["horizontal_scroll"] = "The 'horizontal_scroll' option has been removed. Horizontal scrolling is always enabled.",
    ["max_length"] = "The 'max_length' option has been deprecated. Use 'options.max_delta'.",
    ["scroll_limit"] = "The 'scroll_limit' option has been deprecated. Use 'options.max_delta'.",
}

function M.setup(config)
    if config == nil then
        return
    end

    -- Check for deprecated options.
    for option, message in pairs(deprecated) do
        local keys = vim.split(option, ".", { plain = true })
        if vim.tbl_get(config, unpack(keys)) ~= nil then
            vim.notify("[cinnamon.config] " .. message, vim.log.levels.WARN)
        end
    end

    -- Convert deprecated options to new options.
    if config.default_keymaps ~= nil then
        config.keymaps = {
            basic = config.default_keymaps,
        }
    end
    if config.extra_keymaps ~= nil then
        config.keymaps = {
            basic = config.extra_keymaps,
            extra = config.extra_keymaps,
        }
    end
    if config.extended_keymaps == true then
        config.keymaps = {
            extra = true,
        }
    end
    if config.default_delay ~= nil then
        config.options = {
            delay = config.default_delay,
        }
    end
    if config.scroll_limit ~= nil then
        config.options = {
            max_delta = {
                line = (config.scroll_limit <= 0) and 9999 or config.scroll_limit,
            },
        }
    end

    -- Merge user options with defaults.
    M.config = vim.tbl_deep_extend("force", {}, M.config, config)
end

return M
