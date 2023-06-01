local M = {}

function M.table_to_str(t)
  local ret = ''
  for _, value in ipairs(t) do
    ret = ret .. tostring(value)
  end
  return ret
end

function M.str_to_table(str)
  local t = {}
  for i = 1, #str do
    t[i] = str:sub(i, i)
  end
  return t
end

--- Copies an array and returns it because lua usually does references
---@generic T
---@param t T[]
---@return T[]
function M.array_copy(t)
  local ret = {}
  for _, value in ipairs(t) do
    table.insert(ret, value)
  end
  return ret
end


--- Deep copy a table, deeply excluding certain keys
function M.deepcopy_excluding(t, keys)
  local res = {}
    
  for key, value in pairs(t) do
    if not vim.tbl_contains(keys, key) then
      if type(value) == "table" then
        res[key] = M.deepcopy_excluding(value, keys)
      else
        res[key] = value
      end
    end
  end

  return res
end

return M
