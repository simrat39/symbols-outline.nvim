local M = {}

local SYMBOL_COMPONENT = 27
local SYMBOL_FRAGMENT = 28

function M.should_use_provider(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, 'ft')
  local has_ts, parsers = pcall(require, 'nvim-treesitter.parsers')
  local _, has_parser = pcall(function()
    if has_ts then
      return parsers.get_parser(bufnr) ~= nil
    end

    return false
  end)

  return has_ts
    and has_parser
    and (
      string.match(ft, 'typescriptreact')
      or string.match(ft, 'javascriptreact')
    )
end

function M.hover_info(_, _, on_info)
  on_info(nil, {
    contents = {
      kind = 'nvim-lsp-jsx',
      contents = { 'No extra information availaible!' },
    },
  })
end

local function get_open_tag(node)
  if node:type() == 'jsx_element' then
    for _, outer in ipairs(node:field 'open_tag') do
      if outer:type() == 'jsx_opening_element' then
        return outer
      end
    end
  end

  return nil
end

local function jsx_node_detail(node, buf)
  node = get_open_tag(node) or node

  local param_nodes = node:field 'attribute'
  if #param_nodes == 0 then
    return nil
  end

  local res = '{ '
    .. table.concat(
      vim.tbl_map(function(el)
        local a, b, c, d = el:range()
        local text = vim.api.nvim_buf_get_text(buf, a, b, c, d, {})
        return text[1]
      end, param_nodes),
      ' '
    )
    .. ' }'

  return res
end

local function jsx_node_tagname(node, buf)
  local tagnode = get_open_tag(node) or node

  local identifier = nil

  for _, val in ipairs(tagnode:field 'name') do
    if val:type() == 'identifier' then
      identifier = val
    end
  end

  if identifier then
    local a, b, c, d = identifier:range()
    local text = vim.api.nvim_buf_get_text(buf, a, b, c, d, {})
    local name = table.concat(text)
    return name
  end
end

local function convert_ts(child, children, bufnr)
  local is_frag = (child:type() == 'jsx_fragment')

  local a, b, c, d = child:range()
  local range = {
    start = { line = a, character = b },
    ['end'] = { line = c, character = d },
  }

  local converted = {
    name = (not is_frag and (jsx_node_tagname(child, bufnr) or '<unknown>'))
      or 'fragment',
    children = (#children > 0 and children) or nil,
    kind = (is_frag and SYMBOL_FRAGMENT) or SYMBOL_COMPONENT,
    detail = jsx_node_detail(child, bufnr),
    range = range,
    selectionRange = range,
  }

  return converted
end

local function parse_ts(root, children, bufnr)
  children = children or {}

  for child in root:iter_children() do
    if
      vim.tbl_contains(
        { 'jsx_element', 'jsx_self_closing_element' },
        child:type()
      )
    then
      local new_children = {}

      parse_ts(child, new_children, bufnr)

      table.insert(children, convert_ts(child, new_children, bufnr))
    else
      parse_ts(child, children, bufnr)
    end
  end

  return children
end

function M.request_symbols(on_symbols)
  local parsers = require 'nvim-treesitter.parsers'
  local bufnr = 0

  local parser = parsers.get_parser(bufnr)
  local root = parser:parse()[1]:root()

  local symbols = parse_ts(root, nil, bufnr)
  -- local symbols = convert_ts(ctree)
  on_symbols { [1000000] = { result = symbols } }
end

return M
