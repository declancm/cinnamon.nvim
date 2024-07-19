local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error
local info = vim.health.info or vim.health.report_info

local M = {}

M.check = function()
    start("cinnamon.nvim")

    if vim.o.wrap then
        warn("'wrap' is enabled. This will cause issues with the animations.")
    else
        ok("'wrap' is disabled.")
    end
end

return M
