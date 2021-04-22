local vim = vim

local parser = require('symbols-outline.parser')
local ui = require('symbols-outline.ui')
local writer = require('symbols-outline.writer')

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

function D._refresh()
    if D.state.outline_buf ~= nil then
        vim.lsp.buf_request(0, "textDocument/documentSymbol", getParams(),
                            function(_, _, result)

            D.state.code_win = vim.api.nvim_get_current_win()
            D.state.outline_items = parser.parse(result)
            D.state.flattened_outline_items =
                parser.flatten(parser.parse(result))

            writer.parse_and_write(D.state.outline_buf, D.state.outline_win,
                                   D.state.outline_items,
                                   D.state.flattened_outline_items)
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
    ui.clear_hover_highlight(D.state.outline_buf)
    for _, value in ipairs(nodes) do
        ui.add_hover_highlight(D.state.outline_buf, value.line_in_outline - 1,
                               value.depth * 2)
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
    -- hover symbol
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-space>",
                                ":lua require('symbols-outline.hover').show_hover()<Cr>",
                                {})
    -- rename symbol
    vim.api.nvim_buf_set_keymap(bufnr, "n", "r",
                                ":lua require('symbols-outline.rename').rename()<Cr>",
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
    D.state.outline_items = parser.parse(result)
    D.state.flattened_outline_items = parser.flatten(parser.parse(result))

    writer.parse_and_write(D.state.outline_buf, D.state.outline_win,
                           D.state.outline_items,
                           D.state.flattened_outline_items)
    ui.setup_highlights()
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
