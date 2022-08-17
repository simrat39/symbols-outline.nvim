local vim = vim

local main = require 'symbols-outline'

local M = {}

local function get_action_params(node, winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local fn = 'file://' .. vim.api.nvim_buf_get_name(bufnr)

  local pos = { line = node.line, character = node.character }
  local diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr, node.line)
  return {
    textDocument = { uri = fn },
    range = { start = pos, ['end'] = pos },
    context = { diagnostics = diagnostics },
    bufnr = bufnr,
  }
end

function M.show_code_actions()
  local current_line = vim.api.nvim_win_get_cursor(main.state.outline_win)[1]
  local node = main.state.flattened_outline_items[current_line]

  local params = get_action_params(node, main.state.code_win)
  vim.lsp.buf_request(
    params.bufnr,
    'textDocument/codeAction',
    params,
    vim.lsp.handlers['textDocument/codeAction']
  )
end

return M
