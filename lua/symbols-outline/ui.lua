local vim = vim
local symbols = require('symbols-outline.symbols')
local M = {}

M.markers = {
    bottom = "└",
    middle = "├",
    vertical = "│",
    horizontal = "─"
}

M.hovered_hl_ns = vim.api.nvim_create_namespace("hovered_item")

function M.clear_hover_highlight(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, M.hovered_hl_ns, 0, -1)
end

function M.add_hover_highlight(bufnr, line, col_start)
    vim.api.nvim_buf_add_highlight(bufnr, M.hovered_hl_ns, "FocusedSymbol",
                                   line, col_start, -1)

end

local function highlight_text(name, text, hl_group)
    vim.cmd(string.format("syn match %s /%s/", name, text))
    vim.cmd(string.format("hi def link %s %s", name, hl_group))
end

function M.setup_highlights()
    -- markers
    highlight_text("marker_middle", M.markers.middle, "Comment")
    highlight_text("marker_vertical", M.markers.vertical, "Comment")
    highlight_text("markers_horizontal", M.markers.horizontal, "Comment")
    highlight_text("markers_bottom", M.markers.bottom, "Comment")

    for _, value in ipairs(symbols.kinds) do
        local symbol = symbols[value]
        highlight_text(value, symbol.icon, symbol.hl)
    end
end

return M
