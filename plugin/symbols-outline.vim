if exists('g:loaded_symbols_outline')
    finish
endif
let g:loaded_symbols_outline = 1

command! SymbolsOutline :lua require'symbols-outline'.toggle_outline()
command! SymbolsOutlineOpen :lua require'symbols-outline'.open_outline()
command! SymbolsOutlineClose :lua require'symbols-outline'.close_outline()
