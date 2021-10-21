local config = require('symbols-outline.config')

local M = {}

local function getParams()
    return {textDocument = vim.lsp.util.make_text_document_params()}
end

-- probably change this
function M.should_use_provider(bufnr)
    local clients = vim.lsp.buf_get_clients(bufnr)
    local ret = false

    for id, client in pairs(clients) do
        if config.is_client_blacklisted(id) then
           goto continue
        else
            if client.server_capabilities.documentSymbolProvider then
               ret = true
               break
            end
        end
        ::continue::
    end

    return ret
end

---@param on_symbols function
function M.request_symbols(on_symbols)
    vim.lsp.buf_request_all(0, "textDocument/documentSymbol", getParams(),
                            on_symbols)
end

return M
