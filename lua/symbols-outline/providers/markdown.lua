local md_parser = require('symbols-outline.markdown')

local M = {}

-- probably change this
function M.should_use_provider(bufnr)
    return vim.api.nvim_buf_get_option(bufnr, 'ft') == 'markdown'
end

---@param on_symbols function
function M.request_symbols(on_symbols)
    on_symbols(md_parser.handle_markdown())
end

return M
