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

---@param on_symbols function
function M.request_symbols(on_symbols)
  vim.fn.call('CocActionAsync', {
    'documentSymbols',
    function(_, symbols)
      on_symbols { [1000000] = { result = symbols } }
    end,
  })
end

return M
