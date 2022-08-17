local symbols = require 'symbols-outline.symbols'
local ui = require 'symbols-outline.ui'
local config = require 'symbols-outline.config'
local t_utils = require 'symbols-outline.utils.table'
local folding = require 'symbols-outline.folding'

local M = {}

---Parses result from LSP into a table of symbols
---@param result table The result from a language server.
---@param depth number? The current depth of the symbol in the hierarchy.
---@param hierarchy table? A table of booleans which tells if a symbols parent was the last in its group.
---@param parent table? A reference to the current symbol's parent in the function's recursion
---@return table
local function parse_result(result, depth, hierarchy, parent)
  local ret = {}

  for index, value in pairs(result) do
    if not config.is_symbol_blacklisted(symbols.kinds[value.kind]) then
      -- the hierarchy is basically a table of booleans which tells whether
      -- the parent was the last in its group or not
      local hir = hierarchy or {}
      -- how many parents this node has, 1 is the lowest value because its
      -- easier to work it
      local level = depth or 1
      -- whether this node is the last in its group
      local isLast = index == #result

      -- support SymbolInformation[]
      -- https://microsoft.github.io/language-server-protocol/specification#textDocument_documentSymbol
      local selectionRange = value.selectionRange
      if value.selectionRange == nil then
        selectionRange = value.location.range
      end

      local range = value.range
      if value.range == nil then
        range = value.location.range
      end

      local node = {
        deprecated = value.deprecated,
        kind = value.kind,
        icon = symbols.icon_from_kind(value.kind),
        name = value.name or value.text,
        detail = value.detail,
        line = selectionRange.start.line,
        character = selectionRange.start.character,
        range_start = range.start.line,
        range_end = range['end'].line,
        depth = level,
        isLast = isLast,
        hierarchy = hir,
        parent = parent,
      }

      table.insert(ret, node)

      local children = nil
      if value.children ~= nil then
        -- copy by value because we dont want it messing with the hir table
        local child_hir = t_utils.array_copy(hir)
        table.insert(child_hir, isLast)
        children = parse_result(value.children, level + 1, child_hir, node)
      end

      node.children = children
    end
  end
  return ret
end

---Sorts the result from LSP by where the symbols start.
---@param result table Result containing symbols returned from textDocument/documentSymbol
---@return table
local function sort_result(result)
  ---Returns the start location for a symbol, or nil if not found.
  ---@param item table The symbol.
  ---@return table|nil
  local function get_range_start(item)
    if item.location ~= nil then
      return item.location.range.start
    elseif item.range ~= nil then
      return item.range.start
    else
      return nil
    end
  end

  table.sort(result, function(a, b)
    local a_start = get_range_start(a)
    local b_start = get_range_start(b)

    -- if they both are equal, a should be before b
    if a_start == nil and b_start == nil then
      return false
    end

    -- those with no start go first
    if a_start == nil then
      return true
    end
    if b_start == nil then
      return false
    end

    -- first try to sort by line. If lines are equal, sort by character instead
    if a_start.line ~= b_start.line then
      return a_start.line < b_start.line
    else
      return a_start.character < b_start.character
    end
  end)

  return result
end

---Parses the response from lsp request 'textDocument/documentSymbol' using buf_request_all
---@param response table The result from buf_request_all
---@return table outline items
function M.parse(response)
  local all_results = {}

  -- flatten results to one giant table of symbols
  for client_id, client_response in pairs(response) do
    if config.is_client_blacklisted(client_id) then
      print('skipping client ' .. client_id)
      goto continue
    end

    local result = client_response['result']
    if result == nil or type(result) ~= 'table' then
      goto continue
    end

    for _, value in pairs(result) do
      table.insert(all_results, value)
    end

    ::continue::
  end

  local sorted = sort_result(all_results)

  return parse_result(sorted, nil, nil)
end

function M.flatten(outline_items, ret, depth)
  depth = depth or 1
  ret = ret or {}
  for _, value in ipairs(outline_items) do
    table.insert(ret, value)
    value.line_in_outline = #ret
    if value.children ~= nil and not folding.is_folded(value) then
      M.flatten(value.children, ret, depth + 1)
    end
  end

  -- if depth == 1 then
  --   for index, value in ipairs(ret) do
  --     value.line_in_outline = index
  --   end
  -- end

  return ret
end

function M.get_lines(flattened_outline_items)
  local lines = {}
  local hl_info = {}

  for node_line, node in ipairs(flattened_outline_items) do
    local depth = node.depth
    local marker_space = (config.options.fold_markers and 1) or 0

    local line = t_utils.str_to_table(string.rep(' ', depth + marker_space))
    local running_length = 1

    local function add_guide_hl(from, to)
      table.insert(hl_info, {
        node_line,
        from,
        to,
        'SymbolsOutlineConnector',
      })
    end

    for index, _ in ipairs(line) do
      -- all items start with a space (or two)
      if config.options.show_guides then
        -- makes the guides
        if index == 1 then
          line[index] = ' '
          -- i f index is last, add a bottom marker if current item is last,
          -- else add a middle marker
        elseif index == #line then
          -- add fold markers
          if config.options.fold_markers and folding.is_foldable(node) then
            if folding.is_folded(node) then
              line[index] = config.options.fold_markers[1]
            else
              line[index] = config.options.fold_markers[2]
            end

            add_guide_hl(
              running_length,
              running_length + vim.fn.strlen(line[index]) - 1
            )

            -- the root level has no vertical markers
          elseif depth > 1 then
            if node.isLast then
              line[index] = ui.markers.bottom
              add_guide_hl(
                running_length,
                running_length + vim.fn.strlen(ui.markers.bottom) - 1
              )
            else
              line[index] = ui.markers.middle
              add_guide_hl(
                running_length,
                running_length + vim.fn.strlen(ui.markers.middle) - 1
              )
            end
          end
          -- else if the parent was not the last in its group, add a
          -- vertical marker because there are items under us and we need
          -- to point to those
        elseif not node.hierarchy[index] and depth > 1 then
          line[index + marker_space] = ui.markers.vertical
          add_guide_hl(
            running_length - 1 + 2 * marker_space,
            running_length
              + vim.fn.strlen(ui.markers.vertical)
              - 1
              + 2 * marker_space
          )
        end
      end

      line[index] = line[index] .. ' '

      running_length = running_length + vim.fn.strlen(line[index])
    end

    local final_prefix = line

    local string_prefix = t_utils.table_to_str(final_prefix)

    table.insert(lines, string_prefix .. node.icon .. ' ' .. node.name)

    local hl_start = #string_prefix
    local hl_end = #string_prefix + #node.icon
    local hl_type = config.options.symbols[symbols.kinds[node.kind]].hl
    table.insert(hl_info, { node_line, hl_start, hl_end, hl_type })

    node.prefix_length = #string_prefix + #node.icon + 1
  end
  return lines, hl_info
end

function M.get_details(flattened_outline_items)
  local lines = {}
  for _, value in ipairs(flattened_outline_items) do
    table.insert(lines, value.detail or '')
  end
  return lines
end

return M
