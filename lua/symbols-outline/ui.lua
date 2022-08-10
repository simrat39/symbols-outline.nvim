local vim = vim
local config = require 'symbols-outline.config'
local symbol_kinds = require('symbols-outline.symbols').kinds
local M = {}

M.markers = {
  bottom = '└',
  middle = '├',
  vertical = '│',
  horizontal = '─',
}

M.hovered_hl_ns = vim.api.nvim_create_namespace 'hovered_item'

function M.clear_hover_highlight(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.hovered_hl_ns, 0, -1)
end

function M.add_hover_highlight(bufnr, line, col_start)
  vim.api.nvim_buf_add_highlight(
    bufnr,
    M.hovered_hl_ns,
    'FocusedSymbol',
    line,
    col_start,
    -1
  )
end

local function highlight_text(name, text, hl_group)
  vim.cmd(string.format('syn match %s /%s/', name, text))
  vim.cmd(string.format('hi def link %s %s', name, hl_group))
end

function M.setup_highlights()
  -- Setup the FocusedSymbol highlight group if it hasn't been done already by
  -- a theme or manually set
  if vim.fn.hlexists 'FocusedSymbol' == 0 then
    vim.cmd 'hi FocusedSymbol term=italic,bold cterm=italic ctermbg=yellow ctermfg=darkblue gui=bold,italic guibg=yellow guifg=darkblue'
  end

  -- Some colorschemes do some funky things with the comment highlight, most
  -- notably making them italic, which messes up the outline connector. Fix
  -- this by copying the foreground color from the comment hl into a new
  -- highlight.
  local comment_fg_gui = vim.fn.synIDattr(
    vim.fn.synIDtrans(vim.fn.hlID 'Comment'),
    'fg',
    'gui'
  )

  if vim.fn.hlexists 'SymbolsOutlineConnector' == 0 then
    vim.cmd(
      string.format('hi SymbolsOutlineConnector guifg=%s', comment_fg_gui)
    )
  end

  local symbols = config.options.symbols

  -- markers
  highlight_text('marker_middle', M.markers.middle, 'SymbolsOutlineConnector')
  highlight_text(
    'marker_vertical',
    M.markers.vertical,
    'SymbolsOutlineConnector'
  )
  highlight_text(
    'markers_horizontal',
    M.markers.horizontal,
    'SymbolsOutlineConnector'
  )
  highlight_text('markers_bottom', M.markers.bottom, 'SymbolsOutlineConnector')
end

return M
