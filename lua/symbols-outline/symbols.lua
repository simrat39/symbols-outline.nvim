local config = require 'symbols-outline.config'

local M = {}

M.kinds = {
  [1] = 'File',
  [2] = 'Module',
  [3] = 'Namespace',
  [4] = 'Package',
  [5] = 'Class',
  [6] = 'Method',
  [7] = 'Property',
  [8] = 'Field',
  [9] = 'Constructor',
  [10] = 'Enum',
  [11] = 'Interface',
  [12] = 'Function',
  [13] = 'Variable',
  [14] = 'Constant',
  [15] = 'String',
  [16] = 'Number',
  [17] = 'Boolean',
  [18] = 'Array',
  [19] = 'Object',
  [20] = 'Key',
  [21] = 'Null',
  [22] = 'EnumMember',
  [23] = 'Struct',
  [24] = 'Event',
  [25] = 'Operator',
  [26] = 'TypeParameter',
  [27] = 'Component',
  [28] = 'Fragment',

  -- ccls
  [252] = 'TypeAlias',
  [253] = 'Parameter',
  [254] = 'StaticMethod',
  [255] = 'Macro',
}

function M.icon_from_kind(kind)
  local symbols = config.options.symbols

  if type(kind) == 'string' then
    return symbols[kind].icon
  end

  -- If the kind index is not available then default to 'Object'
  if M.kinds[kind] == nil then
    kind = 19
  end
  return symbols[M.kinds[kind]].icon
end

return M
