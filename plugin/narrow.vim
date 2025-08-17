" plugin/narrow.vim
if exists('g:loaded_narrow_plugin') | finish | endif
let g:loaded_narrow_plugin = 1

" Narrow explicit line range:  :Narrow 100 130   or visually  :'<,'>Narrow
command! -range -nargs=* Narrow call narrow#open_range(bufnr('%'),
      \(<q-args> ==# '' ? <line1> : str2nr(split(<q-args>)[0])),
      \(<q-args> ==# '' ? <line2> : str2nr(split(<q-args>)[1])))

" Project-wide picker
command! NarrowSearch call narrow_search#picker()

" Command to narrow from current position (useful for quickfix)
command! -nargs=? NarrowHere call narrow#open_range(bufnr('%'), line('.'), line('.') + (<q-args> ==# '' ? 30 : str2nr(<q-args>)))

" Autocommand to make Enter key work in quickfix for narrow search results
augroup narrow_quickfix
  autocmd!
  autocmd FileType qf nnoremap <buffer> <CR> :NarrowHere<CR>
augroup END
