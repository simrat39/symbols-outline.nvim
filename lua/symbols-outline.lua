local vim = vim

local parser = require 'symbols-outline.parser'
local providers = require 'symbols-outline.providers.init'
local ui = require 'symbols-outline.ui'
local writer = require 'symbols-outline.writer'
local config = require 'symbols-outline.config'
local utils = require 'symbols-outline.utils.init'
local view = require 'symbols-outline.view'

local M = {}

local function setup_global_autocmd()
  if config.options.highlight_hovered_item then
    vim.cmd "au CursorHold * :lua require('symbols-outline')._highlight_current_item()"
  end
end

local function setup_buffer_autocmd()
  if config.options.auto_preview then
    vim.cmd "au CursorHold <buffer> lua require'symbols-outline.preview'.show()"
  else
    vim.cmd "au CursorMoved <buffer> lua require'symbols-outline.preview'.close()"
  end
end

-------------------------
-- STATE
-------------------------
M.state = {
  outline_items = {},
  flattened_outline_items = {},
  outline_win = nil,
  outline_buf = nil,
  code_win = 0,
}

local function wipe_state()
  M.state = { outline_items = {}, flattened_outline_items = {}, code_win = 0 }
end

local function __refresh()
  if M.state.outline_buf ~= nil then
    local function refresh_handler(response)
      if response == nil or type(response) ~= 'table' then
        return
      end

      local items = parser.parse(response)

      M.state.code_win = vim.api.nvim_get_current_win()
      M.state.outline_items = items
      M.state.flattened_outline_items = parser.flatten(items)

      writer.parse_and_write(M.state.outline_buf, M.state.flattened_outline_items)
    end

    providers.request_symbols(refresh_handler)
  end
end

M._refresh = utils.debounce(__refresh, 100)

function M._goto_location(change_focus)
  local current_line = vim.api.nvim_win_get_cursor(M.state.outline_win)[1]
  local node = M.state.flattened_outline_items[current_line]
  vim.api.nvim_win_set_cursor(M.state.code_win, { node.line + 1, node.character })
  vim.api.nvim_win_call(M.state.code_win, function() vim.cmd 'normal zz' end)
  if change_focus then
    vim.fn.win_gotoid(M.state.code_win)
  end
  if config.options.auto_close then
    M.close_outline()
  end
end

function M._highlight_current_item(winnr)
  local has_provider = providers.has_provider()

  local is_current_buffer_the_outline = M.state.outline_buf == vim.api.nvim_get_current_buf()

  local doesnt_have_outline_buf = not M.state.outline_buf

  local should_exit = not has_provider or doesnt_have_outline_buf or is_current_buffer_the_outline

  -- Make a special case if we have a window number
  -- Because we might use this to manually focus so we dont want to quit this
  -- function
  if winnr then
    should_exit = false
  end

  if should_exit then
    return
  end

  local win = winnr or vim.api.nvim_get_current_win()

  local hovered_line = vim.api.nvim_win_get_cursor(win)[1] - 1

  local nodes = {}
  for index, value in ipairs(M.state.flattened_outline_items) do
    if value.line == hovered_line or (hovered_line > value.range_start and hovered_line < value.range_end) then
      value.line_in_outline = index
      table.insert(nodes, value)
    end
  end

  -- clear old highlight
  ui.clear_hover_highlight(M.state.outline_buf)
  for _, value in ipairs(nodes) do
    ui.add_hover_highlight(M.state.outline_buf, value.line_in_outline - 1, value.depth * 2)
    vim.api.nvim_win_set_cursor(M.state.outline_win, { value.line_in_outline, 1 })
  end
end

local function setup_keymaps(bufnr)
  local map = function(...)
    utils.nmap(bufnr, ...)
  end
  -- goto_location of symbol and focus that window
  map(config.options.keymaps.goto_location, ":lua require('symbols-outline')._goto_location(true)<Cr>")
  -- goto_location of symbol but stay in outline
  map(config.options.keymaps.focus_location, ":lua require('symbols-outline')._goto_location(false)<Cr>")
  -- hover symbol
  map(config.options.keymaps.hover_symbol, ":lua require('symbols-outline.hover').show_hover()<Cr>")
  -- preview symbol
  map(config.options.keymaps.toggle_preview, ":lua require('symbols-outline.preview').toggle()<Cr>")
  -- rename symbol
  map(config.options.keymaps.rename_symbol, ":lua require('symbols-outline.rename').rename()<Cr>")
  -- code actions
  map(config.options.keymaps.code_actions, ":lua require('symbols-outline.code_action').show_code_actions()<Cr>")
  -- show help
  map(config.options.keymaps.show_help, ":lua require('symbols-outline.config').show_help()<Cr>")
  -- close outline
  map(config.options.keymaps.close, ':bw!<Cr>')
end

local function handler(response)
  if response == nil or type(response) ~= 'table' then
    return
  end

  M.state.code_win = vim.api.nvim_get_current_win()

  M.state.outline_buf, M.state.outline_win = view.setup_view()
  -- clear state when buffer is closed
  vim.api.nvim_buf_attach(M.state.outline_buf, false, {
    on_detach = function(_, _)
      wipe_state()
    end,
  })
  setup_keymaps(M.state.outline_buf)
  setup_buffer_autocmd()

  local items = parser.parse(response)

  M.state.outline_items = items
  M.state.flattened_outline_items = parser.flatten(items)

  writer.parse_and_write(M.state.outline_buf, M.state.flattened_outline_items)
  ui.setup_highlights()

  M._highlight_current_item(M.state.code_win)
end

function M.toggle_outline()
  if M.state.outline_buf == nil then
    M.open_outline()
  else
    M.close_outline()
  end
end

function M.open_outline()
  if M.state.outline_buf == nil then
    providers.request_symbols(handler)
  end
end

function M.close_outline()
  if M.state.outline_buf then
    vim.api.nvim_win_close(M.state.outline_win, true)
  end
end

function M.setup(opts)
  config.setup(opts)
  setup_global_autocmd()
end

return M
