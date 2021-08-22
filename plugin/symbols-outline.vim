if exists('g:loaded_symbols_outline')
    finish
endif
let g:loaded_symbols_outline = 1

if exists('g:symbols_outline')
    call luaeval('require"symbols-outline".setup(_A[1])', [g:symbols_outline])
else
    call luaeval('require"symbols-outline".setup()')
endif

command! SymbolsOutline :lua require'symbols-outline'.toggle_outline()
command! SymbolsOutlineOpen :lua require'symbols-outline'.open_outline()
command! SymbolsOutlineClose :lua require'symbols-outline'.close_outline()

au InsertLeave,WinEnter,BufEnter,BufWinEnter,TabEnter,BufWritePost * :lua require('symbols-outline')._refresh()
au WinEnter * lua require'symbols-outline.preview'.close()
