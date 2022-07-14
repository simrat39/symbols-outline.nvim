local M = {}

local providers = {
  'symbols-outline/providers/jsx',
  'symbols-outline/providers/nvim-lsp',
  'symbols-outline/providers/coc',
  'symbols-outline/providers/markdown',
}

_G._symbols_outline_current_provider = nil

function M.has_provider()
  local ret = false
  for _, value in ipairs(providers) do
    local provider = require(value)
    if provider.should_use_provider(0) then
      ret = true
      break
    end
  end
  return ret
end

---@param on_symbols function
function M.request_symbols(on_symbols)
  for _, value in ipairs(providers) do
    local provider = require(value)
    if provider.should_use_provider(0) then
      _G._symbols_outline_current_provider = provider
      provider.request_symbols(on_symbols)
      break
    end
  end
end

return M
