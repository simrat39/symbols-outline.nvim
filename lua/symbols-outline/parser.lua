local symbols = require 'symbols-outline.symbols'
local ui = require 'symbols-outline.ui'
local config = require 'symbols-outline.config'

local M = {}

-- copies an array and returns it because lua usually does references
local function array_copy(t)
  local ret = {}
  for _, value in ipairs(t) do
    table.insert(ret, value)
  end
  return ret
end

---Parses result from LSP into a table of symbols
---@param result table The result from a language server.
---@param depth number The current depth of the symbol in the hierarchy.
---@param hierarchy table A table of booleans which tells if a symbols parent was the last in its group.
---@return table
local function parse_result(result, depth, hierarchy)
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

      local children = nil
      if value.children ~= nil then
        -- copy by value because we dont want it messing with the hir table
        local child_hir = array_copy(hir)
        table.insert(child_hir, isLast)
        children = parse_result(value.children, level + 1, child_hir)
      end

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

      table.insert(ret, {
        deprecated = value.deprecated,
        kind = value.kind,
        icon = symbols.icon_from_kind(value.kind),
        name = value.name or value.text,
        detail = value.detail,
        line = selectionRange.start.line,
        character = selectionRange.start.character,
        range_start = range.start.line,
        range_end = range['end'].line,
        children = children,
        depth = level,
        isLast = isLast,
        hierarchy = hir,
      })
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

  return parse_result(sorted)
end

function M.flatten(outline_items)
  local ret = {}
  for _, value in ipairs(outline_items) do
    table.insert(ret, value)
    if value.children ~= nil then
      local inner = M.flatten(value.children)
      for _, value_inner in ipairs(inner) do
        table.insert(ret, value_inner)
      end
    end
  end
  return ret
end

local function table_to_str(t)
  local ret = ''
  for _, value in ipairs(t) do
    ret = ret .. tostring(value)
  end
  return ret
end

local function str_to_table(str)
  local t = {}
  for i = 1, #str do
    t[i] = str:sub(i, i)
  end
  return t
end

function M.get_lines(flattened_outline_items)
  local lines = {}
  local hl_info = {}
  for _, value in ipairs(flattened_outline_items) do
    local line = str_to_table(string.rep(' ', value.depth))

    if config.options.show_guides then
      -- makes the guides
      for index, _ in ipairs(line) do
        -- do not print unnecessary spaces before items
        if index == 1 then
          line[index] = nil
          -- if index is last, add a bottom marker if current item is last,
          -- else add a middle marker
        elseif index == #line then
          if value.isLast then
            line[index] = ui.markers.bottom
          else
            line[index] = ui.markers.middle
          end
          -- else if the parent was not the last in its group, add a
          -- vertical marker because there are items under us and we need
          -- to point to those
        elseif not value.hierarchy[index] then
          line[index] = ui.markers.vertical
        end
      end
    end

    local final_prefix = {}
    -- Add 1 space between the guides
    for _, v in pairs(line) do
      table.insert(final_prefix, v)
      table.insert(final_prefix, ' ')
    end

    local string_prefix = table_to_str(final_prefix)
    local hl_start = #string_prefix
    local hl_end = #string_prefix + #value.icon
    table.insert(lines, string_prefix .. value.icon .. ' ' .. value.name)
    hl_type = config.options.symbols[symbols.kinds[value.kind]].hl
    table.insert(hl_info, { hl_start, hl_end, hl_type })
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
