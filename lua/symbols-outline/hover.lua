local vim = vim

local main = require('symbols-outline')
local util = vim.lsp.util
local buf_request = require('symbols-outline.utils.lsp_utils').request

local M = {}

local function get_hover_params(node, winnr)
    local bufnr = vim.api.nvim_win_get_buf(winnr)
    local fn = vim.uri_from_bufnr(bufnr)

    return {
        textDocument = {uri = fn},
        position = {line = node.line, character = node.character},
        bufnr = bufnr
    }
end

-- handler yoinked from the default implementation
function M.show_hover()
    local current_line = vim.api.nvim_win_get_cursor(main.state.outline_win)[1]
    local node = main.state.flattened_outline_items[current_line]

    local hover_params = get_hover_params(node, main.state.code_win)

    buf_request(hover_params.bufnr, "textDocument/hover", hover_params,
                        function(_, result, _, config)

        if not (result and result.contents) then
            -- return { 'No information available' }
            return
        end
        local markdown_lines = util.convert_input_to_markdown_lines(
                                   result.contents)
        markdown_lines = util.trim_empty_lines(markdown_lines)
        if vim.tbl_isempty(markdown_lines) then
            -- return { 'No information available' }
            return
        end
        return util.open_floating_preview(markdown_lines, "markdown", config)
    end)
end

return M
