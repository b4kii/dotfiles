local colorscheme = "ayu-mirage"

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)

if not status_ok then
    vim.notify("colorscheme " .. colorscheme .. "not found!")
end
-- vim.cmd("colorscheme ayu-mirage")
