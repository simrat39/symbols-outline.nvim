if exists('g:loaded_symbols_outline')
    finish
endif
let g:loaded_symbols_outline = 1

if exists('g:symbols_outline')
    call luaeval('require"symbols-outline".setup(_A[1])', [g:symbols_outline])
else
    call luaeval('require"symbols-outline".setup()')
endif

