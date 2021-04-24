local vim = vim

local M = {}

function M.is_buf_attached_to_lsp(bufnr)
    local clients = vim.lsp.buf_get_clients(bufnr or 0)
    return clients ~= nil and #clients > 0
end

return M
