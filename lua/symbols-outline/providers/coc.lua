-- local config = require('symbols-outline.config')

local M = {}

-- probably change this
function M.should_use_provider(_)
    local coc_installed = vim.fn.exists("*CocActionAsync")

    if not coc_installed then return end

    local coc_attached = vim.fn.call('CocAction', {'ensureDocument'})
    local has_symbols = vim.fn.call('CocHasProvider', {'documentSymbol'})

    return coc_attached and has_symbols;
end

---@param on_symbols function
function M.request_symbols(on_symbols)
    vim.fn.call('CocActionAsync', {'documentSymbols', function (_, symbols)
        on_symbols{[1000000]={result=symbols}}
    end})
end

return M
