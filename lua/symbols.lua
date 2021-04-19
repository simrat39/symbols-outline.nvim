M = {}

M.File = ""
M.Module = ""
M.Namespace = ""
M.Package = ""
M.Class = ""
M.Method = "ƒ"
M.Property = ""
M.Field = ""
M.Constructor = ""
M.Enum = "ℰ"
M.Interface = "ﰮ"
M.Function = ""
M.Variable = ""
M.Constant = ""
M.String = "𝓐"
M.Number = "#"
M.Boolean = "⊨"
M.Array = ""
M.Object = "object"
M.Key = "🔐"
M.Null = "NULL"
M.EnumMember = ""
M.Struct = ""
M.Event = "🗲"
M.Operator = "𝒯"

M.kinds = {
    "File", "Module", "Namespace", "Package", "Class", "Method", "Property",
    "Field", "Constructor", "Enum", "Interface", "Function", "Variable",
    "Constant", "String", "Number", "Boolean", "Array", "Object", "Key", "Null",
    "EnumMember", "Struct", "Event", "Operator"
}

function M.icon_from_kind(kind)
   return M[M.kinds[kind]]
end

return M
