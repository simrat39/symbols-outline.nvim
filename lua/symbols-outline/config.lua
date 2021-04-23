local vim = vim

local M = {}

local defaults = {
    highlight_hovered_item = true,
}

M.options = {}

function M.setup(options)
   M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

return M
