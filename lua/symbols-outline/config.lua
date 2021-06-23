local vim = vim

local M = {}

local defaults = {
    highlight_hovered_item = true,
    show_guides = true,
    position = 'right',
    auto_preview = true,
    show_numbers = false,
    show_relative_numbers = false,
    show_symbol_details = true,
    keymaps = {
        close = "<Esc>",
        goto_location = "<Cr>",
        focus_location = "o",
        hover_symbol = "<C-space>",
        rename_symbol = "r",
        code_actions = "a"
    },
    lsp_blacklist = {}
}

M.options = {}

function M.has_numbers()
   return M.options.show_numbers or M.options.show_relative_numbers
end

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
        return "botright vs"
    end
end

local function has_value(tab, val)
    for _, value in ipairs(tab) do if value == val then return true end end

    return false
end

function M.is_client_blacklisted(client_id)
    local client = vim.lsp.get_client_by_id(client_id)
    return has_value(M.options.lsp_blacklist, client.name)
end

function M.setup(options)
    M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

return M
