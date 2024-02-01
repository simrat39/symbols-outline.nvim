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

    local next_value = lines[line+1]
    local is_emtpy_line = #value:gsub("^%s*(.-)%s*$", "%1") == 0

    local header, title = string.match(value, '^(#+)%s+(.*)$')
    if not header and next_value and not is_emtpy_line then
      if string.match(next_value, '^=+%s*$') then
        header = '#'
        title = value
      elseif string.match(next_value, '^-+%s*$') then
        header = '##'
        title = value
      end
    end

    if header and not is_inside_code_block then
      local depth = #header + 1

      local parent
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

      local entry = {
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

  return level_symbols[1].children
end

return M
