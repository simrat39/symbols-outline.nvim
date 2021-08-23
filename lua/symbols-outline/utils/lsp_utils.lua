local vim = vim

local M = {}

function M.is_buf_attached_to_lsp(bufnr)
    local clients = vim.lsp.buf_get_clients(bufnr or 0)
    return clients ~= nil and #clients > 0
end

function M.is_buf_markdown(bufnr)
    return vim.api.nvim_buf_get_option(bufnr, 'ft') == 'markdown'
end

---@param bufnr number
---@return boolean
function M.should_not_refresh(bufnr)
    if (not M.is_buf_markdown(bufnr)) and (not M.is_buf_attached_to_lsp(bufnr)) then
        return true
    end
    return false
end

return M
