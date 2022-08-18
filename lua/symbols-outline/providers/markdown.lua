local md_parser = require 'symbols-outline.markdown'

local M = {}

-- probably change this
function M.should_use_provider(bufnr)
  return string.match(vim.api.nvim_buf_get_option(bufnr, 'ft'), 'markdown')
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
  on_symbols(md_parser.handle_markdown())
end

return M
