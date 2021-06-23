local vim = vim

local parser = require('symbols-outline.parser')
local config = require('symbols-outline.config')

local M = {}

local function is_buffer_outline(bufnr)
    local isValid = vim.api.nvim_buf_is_valid(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
    return string.match(name, "OUTLINE") ~= nil and ft == "Outline" and isValid
end

function M.write_outline(bufnr, lines)
    if not is_buffer_outline(bufnr) then return end
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

function M.write_details(bufnr, lines)
    if not is_buffer_outline(bufnr) then return end
    if not config.options.show_symbol_details then return end

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
function M.parse_and_write(bufnr, flattened_outline_items)
    local lines = parser.get_lines(flattened_outline_items)
    M.write_outline(bufnr, lines)

    clear_virt_text(bufnr)
    local details = parser.get_details(flattened_outline_items)
    M.write_details(bufnr, details)
end

return M
