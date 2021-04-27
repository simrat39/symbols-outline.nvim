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
}
```

```vim
" init.vim
let g:symbols_outline = {}
let g:symbols_outline.highlight_hovered_item = v:true
let g:symbols_outline.show_guides = v:true
let g:symbols_outline.position = 'right'
```

| Property | Description | Type | Default | 
| --- | -- | -- | -- |
| highlight_hovered_item | Whether to highlight the currently hovered symbol (high cpu usage) | boolean | true |
| show_guides | Wether to show outline guides | boolean | true |
| position | Where to open the split window | 'right' or 'left' | 'right' |

### Commands

| Command                | Description            |
| ---------------------- | ---------------------- |
| `:SymbolsOutline`      | Toggle symbols outline |
| `:SymbolsOutlineOpen`  | Open symbols outline   |
| `:SymbolsOutlineClose` | Close symbols outline  |

### Keymaps

| Key | Action |
| -- | -- |
| Escape | Close outline |
| Enter | Go to symbol location in code |
| o | Go to symbol location in code without losing focus |
| Ctrl+Space | Hover current symbol | 
| r | Rename symbol |
| a | Code actions |

