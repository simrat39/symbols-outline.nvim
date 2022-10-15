local M = {}

function M.should_use_provider(_)
  local not_coc_installed = vim.fn.exists '*CocActionAsync' == 0
  local not_coc_service_initialized = vim.g.coc_service_initialized == 0

  if not_coc_installed or not_coc_service_initialized then
    return
  end

  local coc_attached = vim.fn.call('CocAction', { 'ensureDocument' })
  local has_symbols = vim.fn.call('CocHasProvider', { 'documentSymbol' })

  return coc_attached and has_symbols
end

function M.hover_info(_, _, on_info)
  on_info(nil, {
    contents = {
      kind = 'markdown',
      contents = { 'No extra information availaible!' },
    },
  })
end

---@param result table
local function convert_symbols(result)
    local s = {}
    local kinds_index = {}
    -- create a inverse indexing of symbols.kind
    local symbols = require("symbols-outline.symbols")
    for k, v in pairs(symbols.kinds) do
        kinds_index[v] = k
    end
    -- rebuild coc.nvim symbol list hierarchy according to the 'level' key
    for _, value in pairs(result) do
        value.children = {}
        value.kind = kinds_index[value.kind]
        if #s == 0 then
            table.insert(s, value)
            goto continue
        end
        if value.level == s[#s].level then
            if value.level == 0 then
                table.insert(s, value)
                goto continue
            end
            local tmp = s[#s]
            table.remove(s)
            table.insert(s[#s].children, tmp)
            table.insert(s, value)
        elseif value.level == s[#s].level + 1 then
            table.insert(s[#s].children, value)
        elseif value.level == s[#s].level + 2 then
            local tmp = s[#s].children[#(s[#s].children)]
            table.remove(s[#s].children)
            table.insert(s, tmp)
            table.insert(s[#s].children, value)
        elseif value.level < s[#s].level then
            while value.level < s[#s].level do
                local tmp = s[#s]
                table.remove(s)
                table.insert(s[#s].children, tmp)
            end
            if s[#s].level ~= 0 then
                local tmp = s[#s]
                table.remove(s)
                table.insert(s[#s].children, tmp)
                table.insert(s, value)
            else
                table.insert(s, value)
            end
        end
        ::continue::
    end
    local top = s[#s]
    while top.level ~= 0 do
        table.remove(s)
        table.insert(s[#s].children, top)
        top = s[#s]
    end
    return s
end

---@param on_symbols function
function M.request_symbols(on_symbols)
  vim.fn.call('CocActionAsync', {
    'documentSymbols',
    function(_, symbols)
      on_symbols { [1000000] = { result = convert_symbols(symbols) } }
    end,
  })
end

return M
