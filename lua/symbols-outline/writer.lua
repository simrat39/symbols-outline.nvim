local vim = vim

local parser = require('symbols-outline.parser')

local M = {}

function M.write_outline(bufnr, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

function M.write_details(bufnr, lines)
    for index, value in ipairs(lines) do
        vim.api.nvim_buf_set_virtual_text(bufnr, -1, index - 1,
                                          {{value, "Comment"}}, {})
    end
end

local function clear_virt_text(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
end

-- runs the whole writing routine where the text is cleared, new data is parsed
-- and then written
function M.parse_and_write(bufnr, winnr, outline_items, flattened_outline_items)
    local lines = parser.get_lines(flattened_outline_items)
    M.write_outline(bufnr, lines)

    clear_virt_text(bufnr)
    local details = parser.get_details(outline_items, bufnr, winnr)
    M.write_details(bufnr, details)
end

return M
