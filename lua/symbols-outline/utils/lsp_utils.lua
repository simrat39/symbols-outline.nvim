local config = require 'symbols-outline.config'
local tbl_utils = require 'symbols-outline.utils.table'

local M = {}

function M.is_buf_attached_to_lsp(bufnr)
  local clients = vim.lsp.buf_get_clients(bufnr or 0)
  return clients ~= nil and #clients > 0
end

function M.is_buf_markdown(bufnr)
  return vim.api.nvim_buf_get_option(bufnr, 'ft') == 'markdown'
end

--- Merge all client token lists in an LSP response
function M.flatten_response(response)
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

  return all_results
end

function M.get_selection_range(token)
  -- support symbolinformation[]
  -- https://microsoft.github.io/language-server-protocol/specification#textdocument_documentsymbol
  if token.selectionRange == nil then
    return token.location.range
  end

  return token.selectionRange
end

function M.get_range(token)
  if token == nil then
    return {
      start={ line=math.huge, character=math.huge },
      ['end']={ line=-math.huge, character=-math.huge },
    }
  end

  -- support symbolinformation[]
  -- https://microsoft.github.io/language-server-protocol/specification#textdocument_documentsymbol
  if token.range == nil then
    return token.location.range
  end

  return token.range
end

--- lexicographically strict compare Ranges, line first
--- https://microsoft.github.io/language-server-protocol/specification/#range
local function range_compare(a, b)
  if a == nil and b == nil then
    return true
  end

  if a == nil then
    return true
  end

  if b == nil then
    return false
  end

  return (a.line < b.line) or (a.line == b.line and a.character < b.character)
end

--- Sorts the result from LSP by where the symbols start.
function M.sort_symbols(symbols)
  table.sort(symbols, function(a, b)
    return range_compare(
      M.get_range(a).start,
      M.get_range(b).start
    )
  end)

  for _, child in ipairs(symbols) do
    if child.children ~= nil then
      M.sort_symbols(child.children)
    end
  end

  return symbols
end

--- Preorder DFS iterator on the symbol tree
function M.symbol_preorder_iter(symbols)
  local stk = {}

  local function push_stk(symbols_list)
    for i = #symbols_list, 1, -1 do
      table.insert(stk, symbols_list[i])
    end
  end

  push_stk(symbols)

  local function is_empty()
    return #stk == 0
  end

  local function next()
    if not is_empty() then
      local top = table.remove(stk)

      push_stk(top and top.children or {})

      return top
    end
  end

  local function peek()
    return stk[#stk]
  end

  return { next=next, is_empty=is_empty, peek=peek }
end

local function merge_symbols_rec(iter1, iter2, ub)
  local res = {}

  while not (iter1.is_empty() and iter2.is_empty()) do
    local bv1 = ((not iter1.is_empty()) and M.get_range(iter1.peek()).start) or { line=math.huge, character=math.huge }
    local bv2 = ((not iter2.is_empty()) and M.get_range(iter2.peek()).start) or { line=math.huge, character=math.huge }

    local iter = (range_compare(bv1, bv2) and iter1) or iter2

    if ub ~= nil and range_compare(ub, M.get_range(iter.peek()).start) then
      break
    end

    local node = iter.next()

    node.new_children = merge_symbols_rec(iter1, iter2, M.get_range(node)['end'])

    table.insert(res, node)
  end

  return res
end

--- Merge symbols from two symbol trees
--- NOTE: Symbols are mutated!
function M.merge_symbols(symbols1, symbols2)
  M.sort_symbols(symbols1)
  M.sort_symbols(symbols2)

  local iter1 = M.symbol_preorder_iter(symbols1)
  local iter2 = M.symbol_preorder_iter(symbols2)

  local symbols = merge_symbols_rec(iter1, iter2)

  local function dfs(nodes)
    for _, node in ipairs(nodes) do
      dfs(node.new_children or {})

      node.children = node.new_children
      node.new_children = nil
    end
  end

  dfs(symbols)

  return symbols
end

return M
