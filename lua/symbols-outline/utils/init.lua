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

function M.items_dfs(callback, children)
  for _, val in ipairs(children) do
    callback(val)

    if val.children then
      M.items_dfs(callback, val.children)
    end
  end
end

---Merges a symbol tree recursively, only replacing nodes
---which have changed. This will maintain the folding
---status of any unchanged nodes.
---@param new_node table New node
---@param old_node table Old node
---@param index? number Index of old_item in parent
---@param parent? table Parent of old_item
M.merge_items_rec = function(new_node, old_node, index, parent)
  local failed = false

  if not new_node or not old_node then
    failed = true
  else
    for key, _ in pairs(new_node) do
      if
        vim.tbl_contains({
          'parent',
          'children',
          'folded',
          'hovered',
          'line_in_outline',
          'hierarchy',
        }, key)
      then
        goto continue
      end

      if key == 'name' then
        -- in the case of a rename, just rename the existing node
        old_node['name'] = new_node['name']
      else
        if not vim.deep_equal(new_node[key], old_node[key]) then
          failed = true
          break
        end
      end

      ::continue::
    end
  end

  if failed then
    if parent and index then
      parent[index] = new_node
    end
  else
    local next_new_item = new_node.children or {}

    -- in case new children are created on a node which
    -- previously had no children
    if #next_new_item > 0 and not old_node.children then
      old_node.children = {}
    end

    local next_old_item = old_node.children or {}

    for i = 1, math.max(#next_new_item, #next_old_item) do
      M.merge_items_rec(next_new_item[i], next_old_item[i], i, next_old_item)
    end
  end
end

return M
