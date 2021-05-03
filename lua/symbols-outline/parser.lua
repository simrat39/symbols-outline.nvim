local symbols = require('symbols-outline.symbols')
local ui = require('symbols-outline.ui')
local config = require('symbols-outline.config')

local M = {}

-- copies an array and returns it because lua usually does references
local function array_copy(t)
    local ret = {}
    for _, value in ipairs(t) do table.insert(ret, value) end
    return ret
end

-- parses result into a neat table
function M.parse(result, depth, heirarchy)
    local ret = {}

    for index, value in pairs(result) do
        -- the heirarchy is basically a table of booleans which tells whether
        -- the parent was the last in its group or not
        local hir = heirarchy or {}
        -- how many parents this node has, 1 is the lowest value because its
        -- easier to work it
        local level = depth or 1
        -- whether this node is the last in its group
        local isLast = index == #result

        local children = nil
        if value.children ~= nil then
            -- copy by value because we dont want it messing with the hir table
            local child_hir = array_copy(hir)
            table.insert(child_hir, isLast)
            children = M.parse(value.children, level + 1, child_hir)
        end

        table.insert(ret, {
            deprecated = value.deprecated,
            kind = value.kind,
            icon = symbols.icon_from_kind(value.kind),
            name = value.name,
            detail = value.detail,
            line = value.selectionRange.start.line,
            range_start = value.range.start.line,
            range_end = value.range["end"].line,
            character = value.selectionRange.start.character,
            children = children,
            depth = level,
            isLast = isLast,
            heirarchy = hir
        });
    end
    return ret
end

function M.flatten(outline_items)
    local ret = {}
    for _, value in ipairs(outline_items) do
        table.insert(ret, value)
        if value.children ~= nil then
            local inner = M.flatten(value.children)
            for _, value_inner in ipairs(inner) do
                table.insert(ret, value_inner)
            end
        end
    end
    return ret
end

local function table_to_str(t)
    local ret = ""
    for _, value in ipairs(t) do ret = ret .. tostring(value) end
    return ret
end

local function str_to_table(str)
    local t = {}
    for i = 1, #str do t[i] = str:sub(i, i) end
    return t
end

function M.get_lines(flattened_outline_items)
    local lines = {}
    for _, value in ipairs(flattened_outline_items) do
        local line = str_to_table(string.rep(" ", value.depth))

        if config.options.show_guides then
            -- makes the guides
            for index, _ in ipairs(line) do
                -- all items start with a space (or two)
                if index == 1 then
                    line[index] = " "
                    -- if index is last, add a bottom marker if current item is last,
                    -- else add a middle marker
                elseif index == #line then
                    if value.isLast then
                        line[index] = ui.markers.bottom
                    else
                        line[index] = ui.markers.middle
                    end
                    -- else if the parent was not the last in its group, add a
                    -- vertical marker because there are items under us and we need
                    -- to point to those
                elseif not value.heirarchy[index] then
                    line[index] = ui.markers.vertical
                end
            end
        end

        local final_prefix = {}
        -- Add 1 space between the guides
        for _, v in ipairs(line) do
            table.insert(final_prefix, v)
            table.insert(final_prefix, " ")
        end

        table.insert(lines, table_to_str(final_prefix) .. value.icon .. " " ..
                         value.name)
    end
    return lines
end

function M.get_details(flattened_outline_items)
    local lines = {}
    for _, value in ipairs(flattened_outline_items) do
        table.insert(lines, value.detail or "")
    end
    return lines
end

return M
