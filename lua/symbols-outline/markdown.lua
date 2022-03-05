local M = {}

-- Parses markdown files and returns a table of SymbolInformation[] which is
-- used by the plugin to show the outline.
-- We do this because markdown does not have a LSP.
-- Note that the headings won't have any hierarchy (as of now).
---@return table
function M.handle_markdown()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local level_symbols = { { children = {} } }
  local max_level = 1
  local is_inside_code_block = false

  for line, value in ipairs(lines) do
    if string.find(value, '^```') then
      is_inside_code_block = not is_inside_code_block
    end

    header, title = string.match(value, '^(#+)%s+(.*)$')
    if header and not is_inside_code_block then
      depth = #header + 1

      for i = depth - 1, 1, -1 do
        if level_symbols[i] ~= nil then
          parent = level_symbols[i].children
          break
        end
      end

      for i = depth, max_level do
        if level_symbols[i] ~= nil then
          level_symbols[i].selectionRange['end'].line = line - 1
          level_symbols[i].range['end'].line = line - 1
          level_symbols[i] = nil
        end
      end
      max_level = depth

      entry = {
        kind = 13,
        name = title,
        selectionRange = {
          start = { character = 1, line = line - 1 },
          ['end'] = { character = 1, line = line - 1 },
        },
        range = {
          start = { character = 1, line = line - 1 },
          ['end'] = { character = 1, line = line - 1 },
        },
        children = {},
      }

      parent[#parent + 1] = entry
      level_symbols[depth] = entry
    end
  end

  for i = 2, max_level do
    if level_symbols[i] ~= nil then
      level_symbols[i].selectionRange['end'].line = #lines
      level_symbols[i].range['end'].line = #lines
    end
  end

  return { [1000000] = { result = level_symbols[1].children } }
end

return M
