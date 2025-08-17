" plugin/narrow.vim
if exists('g:loaded_narrow_plugin') | finish | endif
let g:loaded_narrow_plugin = 1

" Narrow explicit line range:  :Narrow 100 130   or visually  :'<,'>Narrow
command! -range -nargs=* Narrow call narrow#open_range(bufnr('%'),
      \(<q-args> ==# '' ? <line1> : str2nr(split(<q-args>)[0])),
      \(<q-args> ==# '' ? <line2> : str2nr(split(<q-args>)[1])))

" Project-wide picker
command! NarrowSearch call narrow_search#picker()
