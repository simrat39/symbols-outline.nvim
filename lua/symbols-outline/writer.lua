local parser = require 'symbols-outline.parser'
local config = require 'symbols-outline.config'
local ui = require 'symbols-outline.ui'

local M = {}

local function is_buffer_outline(bufnr)
  local isValid = vim.api.nvim_buf_is_valid(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  return string.match(name, 'OUTLINE') ~= nil and ft == 'Outline' and isValid
end

local hlns = vim.api.nvim_create_namespace 'symbols-outline-icon-highlight'

function M.write_outline(bufnr, lines)
  if not is_buffer_outline(bufnr) then
    return
  end
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

function M.add_highlights(bufnr, hl_info, nodes)
  for _, line_hl in ipairs(hl_info) do
    local line, hl_start, hl_end, hl_type = unpack(line_hl)
    vim.api.nvim_buf_add_highlight(
      bufnr,
      hlns,
      hl_type,
      line - 1,
      hl_start,
      hl_end
    )
  end

  M.add_hover_highlights(bufnr, nodes)
end

local ns = vim.api.nvim_create_namespace 'symbols-outline-virt-text'

function M.write_details(bufnr, lines)
  if not is_buffer_outline(bufnr) then
    return
  end
  if not config.options.show_symbol_details then
    return
  end

  for index, value in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, index - 1, -1, {
      virt_text = { { value, 'Comment' } },
      virt_text_pos = 'eol',
      hl_mode = 'combine',
    })
  end
end

local function clear_virt_text(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
end

M.add_hover_highlights = function(bufnr, nodes)
  if not config.options.highlight_hovered_item then
    return
  end

  -- clear old highlight
  ui.clear_hover_highlight(bufnr)
  for _, node in ipairs(nodes) do
    if not node.hovered then
      goto continue
    end

    local marker_fac = (config.options.fold_markers and 1) or 0
    if node.prefix_length then
      ui.add_hover_highlight(
        bufnr,
        node.line_in_outline - 1,
        node.prefix_length
      )
    end
    ::continue::
  end
end

-- runs the whole writing routine where the text is cleared, new data is parsed
-- and then written
function M.parse_and_write(bufnr, flattened_outline_items)
  local lines, hl_info = parser.get_lines(flattened_outline_items)
  M.write_outline(bufnr, lines)

  clear_virt_text(bufnr)
  local details = parser.get_details(flattened_outline_items)
  M.add_highlights(bufnr, hl_info, flattened_outline_items)
  M.write_details(bufnr, details)
end

return M
