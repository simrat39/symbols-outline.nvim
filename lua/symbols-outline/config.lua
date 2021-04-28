local vim = vim

local M = {}

local defaults = {
    highlight_hovered_item = true,
    show_guides = true,
    position = 'right',
    keymaps = {
        close = "<Esc>",
        goto_location = "<Cr>",
        focus_location = "o",
        hover_symbol = "<C-space>",
        rename_symbol = "r",
        code_actions = "a",
    }
}

M.options = {}

function M.get_position_navigation_direction()
    if M.options.position == 'left' then
        return 'h'
    else
        return 'l'
    end
end

function M.get_split_command()
    if M.options.position == 'left' then
        return "topleft vs"
    else
        return "vs"
    end
end

function M.setup(options)
    M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

return M
