local main = require 'symbols-outline'

local M = {}

function M.show_code_actions()
  -- keep the cursor info in outline and jump back (or not jump back?)
  local winnr, pos = vim.api.nvim_get_current_win(), vim.api.nvim_win_get_cursor(0)
  main._goto_location(true)
  vim.lsp.buf.code_action()
  vim.fn.win_gotoid(winnr)
  vim.api.nvim_win_set_cursor(winnr, pos)
end

return M
