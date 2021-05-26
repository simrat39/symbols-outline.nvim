local vim = vim

local parser = require('symbols-outline.parser')
local ui = require('symbols-outline.ui')
local writer = require('symbols-outline.writer')
local config = require('symbols-outline.config')
local utils = require('symbols-outline.utils.lsp_utils')

local M = {}

local function setup_commands()
    vim.cmd("command! " .. "SymbolsOutline " ..
                ":lua require'symbols-outline'.toggle_outline()")
    vim.cmd("command! " .. "SymbolsOutlineOpen " ..
                ":lua require'symbols-outline'.open_outline()")
    vim.cmd("command! " .. "SymbolsOutlineClose " ..
                ":lua require'symbols-outline'.close_outline()")
end

local function setup_global_autocmd()
    vim.cmd(
        "au InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost * :lua require('symbols-outline')._refresh()")
    vim.cmd "au BufLeave * lua require'symbols-outline'._prevent_buffer_override()"
    if config.options.auto_preview then
        vim.cmd "au WinEnter * lua require'symbols-outline.preview'.close_if_not_in_outline()"
    end
    if config.options.highlight_hovered_item then
        vim.cmd(
            "autocmd CursorHold * :lua require('symbols-outline')._highlight_current_item()")
    end
end

local function setup_buffer_autocmd()
    if config.options.auto_preview then
        vim.cmd(
            "au CursorHold <buffer> lua require'symbols-outline.preview'.show()")
    end
end

local function getParams()
    return {textDocument = vim.lsp.util.make_text_document_params()}
end

-------------------------
-- STATE
-------------------------
M.state = {
    outline_items = {},
    flattened_outline_items = {},
    outline_win = nil,
    outline_buf = nil,
    code_win = nil
}

local function wipe_state()
    M.state = {outline_items = {}, flattened_outline_items = {}}
end

function M._refresh()
    if M.state.outline_buf ~= nil then
        vim.lsp.buf_request(0, "textDocument/documentSymbol", getParams(),
                            function(_, _, result, client_id)
            if result == nil or type(result) ~= 'table' then return end
            if config.is_client_blacklisted(client_id) then return end
            if not utils.is_buf_attached_to_lsp(vim.api.nvim_get_current_buf()) then
                return
            end

            M.state.code_win = vim.api.nvim_get_current_win()
            M.state.outline_items = parser.parse(result)
            M.state.flattened_outline_items =
                parser.flatten(parser.parse(result))

            writer.parse_and_write(M.state.outline_buf,
                                   M.state.flattened_outline_items)
        end)
    end
end

function M._goto_location(change_focus)
    local current_line = vim.api.nvim_win_get_cursor(M.state.outline_win)[1]
    local node = M.state.flattened_outline_items[current_line]
    vim.api.nvim_win_set_cursor(M.state.code_win,
                                {node.line + 1, node.character})
    if change_focus then vim.fn.win_gotoid(M.state.code_win) end
end

function M._highlight_current_item()
    if M.state.outline_buf == nil or vim.api.nvim_get_current_buf() ==
        M.state.outline_buf or not utils.is_buf_attached_to_lsp() then return end

    local hovered_line = vim.api.nvim_win_get_cursor(
                             vim.api.nvim_get_current_win())[1] - 1

    local nodes = {}
    for index, value in ipairs(M.state.flattened_outline_items) do
        if value.line == hovered_line or
            (hovered_line > value.range_start and hovered_line < value.range_end) then
            value.line_in_outline = index
            table.insert(nodes, value)
        end
    end

    -- clear old highlight
    ui.clear_hover_highlight(M.state.outline_buf)
    for _, value in ipairs(nodes) do
        ui.add_hover_highlight(M.state.outline_buf, value.line_in_outline - 1,
                               value.depth * 2)
        vim.api.nvim_win_set_cursor(M.state.outline_win,
                                    {value.line_in_outline, 1})
    end
end

-- credits: https://github.com/kyazdani42/nvim-tree.lua
function M._prevent_buffer_override()
    vim.schedule(function()
        local curwin = vim.api.nvim_get_current_win()
        local curbuf = vim.api.nvim_win_get_buf(curwin)
        local wins = vim.api.nvim_list_wins()

        if curwin ~= M.state.outline_win or curbuf ~= M.state.outline_buf then
            return
        end

        vim.cmd("buffer " .. M.state.outline_buf)

        local current_win_width = vim.api.nvim_win_get_width(curwin)
        if #wins < 2 then
            vim.cmd(config.get_split_command())
            vim.cmd("vertical resize " .. math.ceil(current_win_width * 0.75))
        else
            vim.cmd("wincmd " .. config.get_position_navigation_direction())
        end

        vim.cmd("buffer " .. curbuf)
        if #wins < 2 then
            vim.cmd("wincmd r")
            vim.cmd("bprev")
        end
    end)
end

local function setup_keymaps(bufnr)
    local function nmap(key, action)
        vim.api.nvim_buf_set_keymap(bufnr, "n", key, action, { silent = true })
    end
    -- goto_location of symbol and focus that window
    nmap(config.options.keymaps.goto_location, ":lua require('symbols-outline')._goto_location(true)<Cr>")
    -- goto_location of symbol but stay in outline
    nmap(config.options.keymaps.focus_location, ":lua require('symbols-outline')._goto_location(false)<Cr>")
    -- hover symbol
    nmap(config.options.keymaps.hover_symbol, ":lua require('symbols-outline.hover').show_hover()<Cr>")
    -- rename symbol
    nmap(config.options.keymaps.rename_symbol, ":lua require('symbols-outline.rename').rename()<Cr>")
    -- code actions
    nmap(config.options.keymaps.code_actions, ":lua require('symbols-outline.code_action').show_code_actions()<Cr>")
    -- close outline
    nmap(config.options.keymaps.close, ":bw!<Cr>")
end

----------------------------
-- WINDOW AND BUFFER STUFF
----------------------------
local function setup_buffer()
    M.state.outline_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_attach(M.state.outline_buf, false,
                            {on_detach = function(_, _) wipe_state() end})
    vim.api.nvim_buf_set_option(M.state.outline_buf, "bufhidden", "delete")

    local current_win = vim.api.nvim_get_current_win()
    local current_win_width = vim.api.nvim_win_get_width(current_win)

    vim.cmd(config.get_split_command())
    vim.cmd("vertical resize " .. math.ceil(current_win_width * 0.25))
    M.state.outline_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.state.outline_win, M.state.outline_buf)

    setup_keymaps(M.state.outline_buf)

    vim.api.nvim_win_set_option(M.state.outline_win, "number", false)
    vim.api.nvim_win_set_option(M.state.outline_win, "relativenumber", false)
    vim.api.nvim_buf_set_name(M.state.outline_buf, "OUTLINE")
    vim.api.nvim_buf_set_option(M.state.outline_buf, "filetype", "Outline")
    vim.api.nvim_buf_set_option(M.state.outline_buf, "modifiable", false)
end

local function handler(_, _, result, client_id)
    if result == nil or type(result) ~= 'table' then return end
    if config.is_client_blacklisted(client_id) then return end

    M.state.code_win = vim.api.nvim_get_current_win()

    setup_buffer()
    setup_buffer_autocmd()
    M.state.outline_items = parser.parse(result)
    M.state.flattened_outline_items = parser.flatten(parser.parse(result))

    writer.parse_and_write(M.state.outline_buf, M.state.flattened_outline_items)
    ui.setup_highlights()
end

function M.toggle_outline()
    if M.state.outline_buf == nil then
        vim.lsp.buf_request(0, "textDocument/documentSymbol", getParams(),
                            handler)
    else
        vim.api.nvim_win_close(M.state.outline_win, true)
    end
end

function M.open_outline()
    if M.state.outline_buf == nil then
        vim.lsp.buf_request(0, "textDocument/documentSymbol", getParams(),
                            handler)
    end
end

function M.close_outline()
    if M.state.outline_buf ~= nil then
        vim.api.nvim_win_close(M.state.outline_win, true)
    end
end

function M.setup(opts)
    config.setup(opts)
    setup_commands()
    setup_global_autocmd()
end

return M
