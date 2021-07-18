local config = require('symbols-outline.config')

local M = {}

M.kinds = {
    "File", "Module", "Namespace", "Package", "Class", "Method", "Property",
    "Field", "Constructor", "Enum", "Interface", "Function", "Variable",
    "Constant", "String", "Number", "Boolean", "Array", "Object", "Key", "Null",
    "EnumMember", "Struct", "Event", "Operator", "TypeParameter"
}

function M.icon_from_kind(kind)
    local symbols = config.options.symbols

    -- If the kind is higher than the available ones then default to 'Object'
    if kind > #M.kinds then kind = 19 end
    return symbols[M.kinds[kind]].icon
end

return M
