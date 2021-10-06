local M = {}

-- Parses markdown files and returns a table of SymbolInformation[] which is
-- used by the plugin to show the outline.
-- We do this because markdown does not have a LSP.
-- Note that the headings won't have any hierarchy (as of now).
---@return table
function M.handle_markdown()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local results = {}

    local is_inside_code_block = false

    for line, value in ipairs(lines) do
        if string.find(value, "^```") then
            is_inside_code_block = not is_inside_code_block
        end

        if string.find(value, "^#+ ") and not is_inside_code_block then
            if #results > 0 then
               results[#results].selectionRange["end"].line = line - 1
               results[#results].range["end"].line = line - 1
            end

            table.insert(results, {
                kind = 13,
                name = value,
                selectionRange = {
                    start = {character = 1, line = line - 1},
                    ["end"] = {character = 1, line = line - 1}
                },
                range = {
                    start = {character = 1, line = line - 1},
                    ["end"] = {character = 1, line = line - 1}
                }
            })
        end
    end

    return {[1000000]={result=results}}
end

return M
