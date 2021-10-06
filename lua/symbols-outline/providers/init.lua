local M = {}

local providers = {
    'symbols-outline/providers/nvim-lsp',
    'symbols-outline/providers/markdown'
}

---@param on_symbols function
function M.request_symbols(on_symbols)
   for _, value in ipairs(providers) do
       local provider = require(value)
       if provider.should_use_provider(0) then
           provider.request_symbols(on_symbols)
           break
       end
    end
end

return M
