local vim = vim
local symbols = require('symbols')

local D = {}

-- needs plenary
local reload = require('plenary.reload').reload_module

function D.R(name)
    reload(name)
    return require(name)
end

local function setup_commands()
    vim.cmd("command! " .. "DSymbolsOutline " ..
                ":lua require'symbols-outline'.R('symbols-outline').toggle_outline()")
    vim.cmd("command! " .. "SymbolsOutline " ..
                ":lua require'symbols-outline'.toggle_outline()")
end

local function setup_autocmd()
    vim.cmd(
        "au InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost * :lua require('symbols-outline')._refresh()")
    vim.cmd "au BufDelete * lua require'symbols-outline'._prevent_buffer_override()"
    if D.opts.highlight_hovered_item then
        vim.cmd(
            "autocmd CursorHold * :lua require('symbols-outline')._highlight_current_item()")
    end
end

local function getParams()
    return {textDocument = vim.lsp.util.make_text_document_params()}
end

-------------------------
-- STATE
-------------------------
D.state = {
    outline_items = {},
    flattened_outline_items = {},
    outline_win = nil,
    outline_buf = nil,
    code_win = nil
}

local function wipe_state()
    D.state = {outline_items = {}, flattened_outline_items = {}}
end

-------------------------
-- UI STUFF
-------------------------
local markers = {
    bottom = "└",
    middle = "├",
    vertical = "│",
    horizontal = "─"
}

local hovered_hl_ns = vim.api.nvim_create_namespace("hovered_item")

local function highlight_text(name, text, hl_group)
    vim.cmd(string.format("syn match %s /%s/", name, text))
    vim.cmd(string.format("hi def link %s %s", name, hl_group))
end

local function setup_highlights()
    -- markers
    highlight_text("marker_middle", markers.middle, "Comment")
    highlight_text("marker_vertical", markers.vertical, "Comment")
    highlight_text("markers_horizontal", markers.horizontal, "Comment")
    highlight_text("markers_bottom", markers.bottom, "Comment")

    for _, value in ipairs(symbols.kinds) do
        local symbol = symbols[value]
        highlight_text(value, symbol.icon, symbol.hl)
    end
    vim.cmd('hi FocusedSymbol guibg=#e50050')
end

----------------------------
-- PARSING AND WRITING STUFF
----------------------------

-- copies an array and returns it because lua usually does references
local function array_copy(t)
    local ret = {}
    for _, value in ipairs(t) do table.insert(ret, value) end
    return ret
end

-- parses result into a neat table
local function parse(result, depth, heirarchy)
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
            children = parse(value.children, level + 1, child_hir)
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

local function flatten(outline_items)
    local ret = {}
    for _, value in ipairs(outline_items) do
        table.insert(ret, value)
        if value.children ~= nil then
            local inner = flatten(value.children)
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

local function get_lines(flattened_outline_items)
    local lines = {}
    for _, value in ipairs(flattened_outline_items) do
        local line = str_to_table(string.rep(" ", value.depth))

        -- makes the guides
        for index, _ in ipairs(line) do
            -- all items start with a space (or two)
            if index == 1 then
                line[index] = " "
                -- if index is last, add a bottom marker if current item is last,
                -- else add a middle marker
            elseif index == #line then
                if value.isLast then
                    line[index] = markers.bottom
                else
                    line[index] = markers.middle
                end
                -- else if the parent was not the last in its group, add a
                -- vertical marker because there are items under us and we need
                -- to point to those
            elseif not value.heirarchy[index] then
                line[index] = markers.vertical
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

local function get_details(outline_items, bufnr, winnr, lines)
    lines = lines or {}
    for _, value in ipairs(outline_items) do

        if value.children ~= nil then
            get_details(value.children, bufnr, winnr, lines)
        end
    end
    return lines
end

local function write_outline(bufnr, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

local function write_details(bufnr, lines)
    for index, value in ipairs(lines) do
        vim.api.nvim_buf_set_virtual_text(bufnr, -1, index - 1,
                                          {{value, "Comment"}}, {})
    end
end

local function clear_virt_text(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
end

function D._refresh()
    if D.state.outline_buf ~= nil then
        vim.lsp.buf_request(0, "textDocument/documentSymbol", getParams(),
                            function(_, _, result)

            D.state.code_win = vim.api.nvim_get_current_win()
            D.state.outline_items = parse(result)
            D.state.flattened_outline_items = flatten(parse(result))

            local lines = get_lines(D.state.flattened_outline_items)
            write_outline(D.state.outline_buf, lines)

            clear_virt_text(D.state.outline_buf)
            local details = get_details(D.state.outline_items,
                                        D.state.outline_buf, D.state.outline_win)
            write_details(D.state.outline_buf, details)
        end)
    end
end

function D._goto_location()
    local current_line = vim.api.nvim_win_get_cursor(D.state.outline_win)[1]
    local node = D.state.flattened_outline_items[current_line]
    vim.fn.win_gotoid(D.state.code_win)
    vim.fn.cursor(node.line + 1, node.character + 1)
end

function D._highlight_current_item()
    if D.state.outline_buf == nil or vim.api.nvim_get_current_buf() ==
        D.state.outline_buf then return end

    local hovered_line = vim.api.nvim_win_get_cursor(
                             vim.api.nvim_get_current_win())[1] - 1

    local nodes = {}
    for index, value in ipairs(D.state.flattened_outline_items) do
        if value.line == hovered_line or
            (hovered_line > value.range_start and hovered_line < value.range_end) then
            value.line_in_outline = index
            table.insert(nodes, value)
        end
    end

    -- clear old highlight
    vim.api.nvim_buf_clear_namespace(D.state.outline_buf, hovered_hl_ns, 0, -1)
    for _, value in ipairs(nodes) do
        vim.api.nvim_buf_add_highlight(D.state.outline_buf, hovered_hl_ns,
                                       "FocusedSymbol",
                                       value.line_in_outline - 1,
                                       value.depth * 2, -1)
        vim.api.nvim_win_set_cursor(D.state.outline_win,
                                    {value.line_in_outline, 1})
    end
end

-- credits: https://github.com/kyazdani42/nvim-tree.lua
function D._prevent_buffer_override()
    vim.schedule(function()
        local curwin = vim.api.nvim_get_current_win()
        local curbuf = vim.api.nvim_win_get_buf(curwin)
        local wins = vim.api.nvim_list_wins()

        if curwin ~= D.state.outline_win or curbuf ~= D.state.outline_buf then
            return
        end

        vim.cmd("buffer " .. D.state.outline_buf)

        local current_win_width = vim.api.nvim_win_get_width(curwin)
        if #wins < 2 then
            vim.cmd("vsplit")
            vim.cmd("vertical resize " .. math.ceil(current_win_width * 0.75))
        else
            vim.cmd("wincmd l")
        end

        vim.cmd("buffer " .. curbuf)
        vim.cmd("bnext")
        vim.cmd("wincmd r")
    end)
end

local function setup_keymaps(bufnr)
    -- goto_location of symbol
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<Cr>",
                                ":lua require('symbols-outline')._goto_location()<Cr>",
                                {})
    -- close outline when escape is pressed
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", ":bw!<Cr>", {})
end

----------------------------
-- WINDOW AND BUFFER STUFF
----------------------------
local function setup_buffer()
    D.state.outline_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_attach(D.state.outline_buf, false,
                            {on_detach = function(_, _) wipe_state() end})
    vim.api.nvim_buf_set_option(D.state.outline_buf, "bufhidden", "delete")

    local current_win = vim.api.nvim_get_current_win()
    local current_win_width = vim.api.nvim_win_get_width(current_win)

    vim.cmd("vsplit")
    vim.cmd("vertical resize " .. math.ceil(current_win_width * 0.25))
    D.state.outline_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(D.state.outline_win, D.state.outline_buf)

    setup_keymaps(D.state.outline_buf)

    vim.api.nvim_win_set_option(D.state.outline_win, "number", false)
    vim.api.nvim_win_set_option(D.state.outline_win, "relativenumber", false)
    vim.api.nvim_buf_set_name(D.state.outline_buf, "OUTLINE")
    vim.api.nvim_buf_set_option(D.state.outline_buf, "modifiable", false)
end

local function handler(_, _, result)
    if result == nil then return end
    D.state.code_win = vim.api.nvim_get_current_win()

    setup_buffer()
    D.state.outline_items = parse(result)
    D.state.flattened_outline_items = flatten(parse(result))

    local lines = get_lines(D.state.flattened_outline_items)
    write_outline(D.state.outline_buf, lines)

    local details = get_details(D.state.outline_items, D.state.outline_buf,
                                D.state.outline_win)
    write_details(D.state.outline_buf, details)
    setup_highlights()
end

function D.toggle_outline()
    if D.state.outline_buf == nil then
        vim.lsp.buf_request(0, "textDocument/documentSymbol", getParams(),
                            handler)
    else
        vim.api.nvim_win_close(D.state.outline_win, true)
    end
end

function D.setup(opts)
    vim.tbl_deep_extend("force", D.opts, opts or {})

    setup_commands()
    setup_autocmd()
end

D.opts = {highlight_hovered_item = true}

return D
