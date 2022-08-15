local M = {}

---maps the table|string of keys to the action
---@param keys table|string
---@param action function|string
function M.nmap(bufnr, keys, action)
  if type(keys) == 'string' then
    keys = { keys }
  end

  for _, lhs in ipairs(keys) do
    vim.keymap.set(
      'n',
      lhs,
      action,
      { silent = true, noremap = true, buffer = bufnr }
    )
  end
end

--- @param  f function
--- @param  delay number
--- @return function
function M.debounce(f, delay)
  local timer = vim.loop.new_timer()

  return function(...)
    local args = { ... }

    timer:start(
      delay,
      0,
      vim.schedule_wrap(function()
        timer:stop()
        f(unpack(args))
      end)
    )
  end
end

return M
