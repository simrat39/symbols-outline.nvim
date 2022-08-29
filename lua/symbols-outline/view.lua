local config = require 'symbols-outline.config'

local View = {}

function View:new()
  return setmetatable({ bufnr = nil, winnr = nil }, { __index = View })
end

---creates the outline window and sets it up
function View:setup_view()
  -- create a scratch unlisted buffer
  self.bufnr = vim.api.nvim_create_buf(false, true)

  -- delete buffer when window is closed / buffer is hidden
  vim.api.nvim_buf_set_option(self.bufnr, 'bufhidden', 'delete')
  -- create a split
  vim.cmd(config.get_split_command())
  -- resize to a % of the current window size
  vim.cmd('vertical resize ' .. config.get_window_width())

  -- get current (outline) window and attach our buffer to it
  self.winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(self.winnr, self.bufnr)

  -- window stuff
  vim.api.nvim_win_set_option(self.winnr, 'number', false)
  vim.api.nvim_win_set_option(self.winnr, 'relativenumber', false)
  vim.api.nvim_win_set_option(self.winnr, 'winfixwidth', true)
  vim.api.nvim_win_set_option(self.winnr, 'list', false)
  vim.api.nvim_win_set_option(self.winnr, 'wrap', config.options.wrap)
  vim.api.nvim_win_set_option(self.winnr, 'linebreak', true) -- only has effect when wrap=true
  vim.api.nvim_win_set_option(self.winnr, 'breakindent', true) -- only has effect when wrap=true
  --  Would be nice to use ui.markers.vertical as part of showbreak to keep
  --  continuity of the tree UI, but there's currently no way to style the
  --  color, apart from globally overriding hl-NonText, which will potentially
  --  mess with other theme/user settings. So just use empty spaces for now.
  vim.api.nvim_win_set_option(self.winnr, 'showbreak', '      ') -- only has effect when wrap=true.
  -- buffer stuff
  vim.api.nvim_buf_set_name(self.bufnr, 'OUTLINE')
  vim.api.nvim_buf_set_option(self.bufnr, 'filetype', 'Outline')
  vim.api.nvim_buf_set_option(self.bufnr, 'modifiable', false)

  if config.options.show_numbers or config.options.show_relative_numbers then
    vim.api.nvim_win_set_option(self.winnr, 'nu', true)
  end

  if config.options.show_relative_numbers then
    vim.api.nvim_win_set_option(self.winnr, 'rnu', true)
  end
end

function View:close()
  vim.api.nvim_win_close(self.winnr, true)
  self.winnr = nil
  self.bufnr = nil
end

function View:is_open()
  return self.winnr
      and self.bufnr
      and vim.api.nvim_buf_is_valid(self.bufnr)
      and vim.api.nvim_win_is_valid(self.winnr)
end

return View
