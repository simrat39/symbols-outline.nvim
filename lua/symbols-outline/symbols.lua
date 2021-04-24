local M = {}

M.File = {icon = "", hl = "TSURI"}
M.Module = {icon = "", hl = "TSNamespace"}
M.Namespace = {icon = "", hl = "TSNamespace"}
M.Package = {icon = "", hl = "TSNamespace"}
M.Class = {icon = "𝓒", hl = "TSType"}
M.Method = {icon = "ƒ", hl = "TSMethod"}
M.Property = {icon = "", hl = "TSMethod"}
M.Field = {icon = "", hl = "TSField"}
M.Constructor = {icon = "", hl = "TSConstructor"}
M.Enum = {icon = "ℰ", hl = "TSType"}
M.Interface = {icon = "ﰮ", hl = "TSType"}
M.Function = {icon = "", hl = "TSFunction"}
M.Variable = {icon = "", hl = "TSConstant"}
M.Constant = {icon = "", hl = "TSConstant"}
M.String = {icon = "𝓐", hl = "TSString"}
M.Number = {icon = "#", hl = "TSNumber"}
M.Boolean = {icon = "⊨", hl = "TSBoolean"}
M.Array = {icon = "", hl = "TSConstant"}
M.Object = {icon = "⦿", hl = "TSType"}
M.Key = {icon = "🔐", hl = "TSType"}
M.Null = {icon = "NULL", hl = "TSType"}
M.EnumMember = {icon = "", hl = "TSField"}
M.Struct = {icon = "𝓢", hl = "TSType"}
M.Event = {icon = "🗲", hl = "TSType"}
M.Operator = {icon = "+", hl = "TSOperator"}
M.TypeParameter = {icon = "𝙏", hl = "TSParameter"}

M.kinds = {
    "File", "Module", "Namespace", "Package", "Class", "Method", "Property",
    "Field", "Constructor", "Enum", "Interface", "Function", "Variable",
    "Constant", "String", "Number", "Boolean", "Array", "Object", "Key", "Null",
    "EnumMember", "Struct", "Event", "Operator", "TypeParameter"
}

function M.icon_from_kind(kind) return M[M.kinds[kind]].icon end

return M
