# symbols-outline.nvim

**A tree like view for symbols in Neovim using the Language Server Protocol.
Supports all your favourite languages.**

![demo](https://github.com/simrat39/rust-tools-demos/raw/master/symbols-demo.gif)

### Prerequisites

- `neovim 0.5+` (nightly)

### Installation

Using `vim-plug`

```vim
Plug 'simrat39/symbols-outline.nvim'
```

### Configuration

Define a global variable `symbols_outline` as follows:

```lua
-- init.lua
vim.g.symbols_outline = {
    highlight_hovered_item = true,
    show_guides = true,
    position = 'right',
    keymaps = {
        close = "<Esc>",
        goto_location = "<Cr>",
        focus_location = "o",
        hover_symbol = "<C-space>",
        rename_symbol = "r",
        code_actions = "a",
    },
    lsp_blacklist = {},
}
```

```vim
" init.vim
let g:symbols_outline = {
    \ "highlight_hovered_item": v:true,
    \ "show_guides": v:true,
    \ "position": 'right',
    \ "keymaps": {
        \ "close": "<Esc>",
        \ "goto_location": "<Cr>",
        \ "focus_location": "o",
        \ "hover_symbol": "<C-space>",
        \ "rename_symbol": "r",
        \ "code_actions": "a",
    \ },
    \ "lsp_blacklist": [],
\ }
```

| Property               | Description                                                        | Type               | Default                  |
| ---------------------- | ------------------------------------------------------------------ | ------------------ | ------------------------ |
| highlight_hovered_item | Whether to highlight the currently hovered symbol (high cpu usage) | boolean            | true                     |
| show_guides            | Wether to show outline guides                                      | boolean            | true                     |
| position               | Where to open the split window                                     | 'right' or 'left'  | 'right'                  |
| keymaps                | Which keys do what                                                 | table (dictionary) | [here](#default-keymaps) |
| lsp_blacklist          | Which lsp clients to ignore                                        | table (array)      | {}                       |

### Commands

| Command                | Description            |
| ---------------------- | ---------------------- |
| `:SymbolsOutline`      | Toggle symbols outline |
| `:SymbolsOutlineOpen`  | Open symbols outline   |
| `:SymbolsOutlineClose` | Close symbols outline  |

### Default keymaps

| Key        | Action                                             |
| ---------- | -------------------------------------------------- |
| Escape     | Close outline                                      |
| Enter      | Go to symbol location in code                      |
| o          | Go to symbol location in code without losing focus |
| Ctrl+Space | Hover current symbol                               |
| r          | Rename symbol                                      |
| a          | Code actions                                       |

