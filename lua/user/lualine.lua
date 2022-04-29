local M = {}

function M.config()
    local status_ok, lualine = pcall(require, 'lualine')

    if not status_ok then
        return
    end

    lualine.setup {
        options = {theme = 'ayu'},
    }
end

return M

