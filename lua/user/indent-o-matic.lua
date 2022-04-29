local M = {}

function M.config()
    local status_ok, indent_matic = pcall(require, 'indent-o-matic')
    if not status_ok then
        return
    end

    indent_matic.setup {
        max_lines = 2048,
        standard_widths = { 2, 4, 8 },
    }
end

return M
