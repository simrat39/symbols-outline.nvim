# symbols-outline.nvim
<b> A tree like view for symbols in Neovim using the Language Server Protocol. Supports all your favourite languages.</b>

![demo](https://github.com/simrat39/rust-tools-demos/raw/master/symbols-demo.gif)

# Prerequisites

- `neovim 0.5+` (nightly)

# Installation

using `vim-plug`

```vim
Plug 'simrat39/symbols-outline.nvim'
```

# Setup
```lua
local opts = {
    -- whether to highlight the currently hovered symbol
    -- disable if your cpu usage is higher than you want it
    -- or you just hate the highlight
    -- default: true
    highlight_hovered_item = true,

    -- whether to show outline guides 
    -- default: true
    show_guides = true,
}

require('symbols-outline').setup(opts)
```

## Commands
```vim
SymbolsOutline 
```
## Keymaps
```vim
Escape --> Close Outline
Enter --> GoTo Symbol location in code
Ctrl + Space --> Hover current symbol
r --> Rename symbol 
```
