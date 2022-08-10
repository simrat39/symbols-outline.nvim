local vim = vim

local M = {}

-- callback args changed in Neovim 0.5.1/0.6. See:
-- https://github.com/neovim/neovim/pull/15504
local function mk_handler(fn)
  return function(...)
    local config_or_client_id = select(4, ...)
    local is_new = type(config_or_client_id) ~= 'number'
    if is_new then
      fn(...)
    else
      local err = select(1, ...)
      local method = select(2, ...)
      local result = select(3, ...)
      local client_id = select(4, ...)
      local bufnr = select(5, ...)
      local config = select(6, ...)
      fn(
        err,
        result,
        { method = method, client_id = client_id, bufnr = bufnr },
        config
      )
    end
  end
end

-- from mfussenegger/nvim-lsp-compl@29a81f3
function M.request(bufnr, method, params, handler)
  return vim.lsp.buf_request(bufnr, method, params, mk_handler(handler))
end

function M.is_buf_attached_to_lsp(bufnr)
  local clients = vim.lsp.buf_get_clients(bufnr or 0)
  return clients ~= nil and #clients > 0
end

function M.is_buf_markdown(bufnr)
  return vim.api.nvim_buf_get_option(bufnr, 'ft') == 'markdown'
end

return M
