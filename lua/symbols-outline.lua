local vim = vim
local symbols = require('symbols')

local D = {}

-- needs plenary
local reload = require('plenary.reload').reload_module

function D.R(name)
    reload(name)
    return require(name)
end

local function setupCommands()
    vim.cmd("command! " .. "SymbolsOutline " ..
                ":lua require'rust-tools-debug'.R('symbols-outline').toggle_outline()")
end

local function getParams()
    return {textDocument = vim.lsp.util.make_text_document_params()}
end

-------------------------
-- STATE
-------------------------
D.state = {
    outline_items = {},
    linear_outline_items = {},
    outline_win = nil,
    outline_buf = nil
}

function D.goto_location()
    local current_line = vim.api.nvim_win_get_cursor(D.state.outline_win)[1]
    local node = D.state.linear_outline_items[current_line]
    vim.cmd("wincmd p")
    vim.fn.cursor(node.line + 1, node.character + 1)
end

-- parses result into a neat table
local function parse(result, depth)
    local ret = {}
    for _, value in pairs(result) do
        local level = depth or 1
        local children = nil
        if value.children ~= nil then
            children = parse(value.children, level + 1)
        end

        table.insert(ret, {
            deprecated = value.deprecated,
            kind = value.kind,
            icon = symbols.icon_from_kind(value.kind),
            name = value.name,
            line = value.selectionRange.start.line,
            character = value.selectionRange.start.character,
            children = children,
            depth = level
        });
    end
    return ret
end

local function make_linear(outline_items)
    local ret = {}
    for _, value in ipairs(outline_items) do
        table.insert(ret, value)
        if value.children ~= nil then
            local inner = make_linear(value.children)
            for _, value_inner in ipairs(inner) do
                table.insert(ret, value_inner)
            end
        end
    end
    return ret
end

local function write(outline_items, bufnr, winnr)
    for _, value in ipairs(outline_items) do
        vim.api.nvim_buf_set_lines(bufnr, -2, -2, false, {
            string.rep(" ", value.depth * 2) .. value.icon .. " " .. value.name
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "<Cr>",
                                    ":lua require('symbols-outline').goto_location()<Cr>",
                                    {})
        if value.children ~= nil then write(value.children, bufnr, winnr) end
    end
end

local function delete_last_line(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, -2, -1, false, {})
end

local function goto_first_line() vim.fn.cursor(1, 1) end

local function handler(_, _, result)
    D.state.outline_buf = vim.api.nvim_create_buf(false, true)

    local current_win = vim.api.nvim_get_current_win()
    local current_win_width = vim.api.nvim_win_get_width(current_win)

    vim.cmd("vsplit")
    vim.cmd("vertical resize " .. math.ceil(current_win_width * 0.25))
    D.state.outline_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(D.state.outline_win, D.state.outline_buf)

    D.state.outline_items = parse(result)
    D.state.linear_outline_items = make_linear(parse(result))

    write(D.state.outline_items, D.state.outline_buf, D.state.outline_win)
    delete_last_line(D.state.outline_buf)
    goto_first_line()
end

function D.toggle_outline()
    vim.lsp.buf_request(0, "textDocument/documentSymbol", getParams(), handler)
end

function D.setup() setupCommands() end

return D
