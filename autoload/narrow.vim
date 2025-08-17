" autoload/narrow.vim  {{{1
if exists('g:autoloaded_narrow') | finish | endif
let g:autoloaded_narrow = 1

function! narrow#open_range(bufnr, start_lnum, end_lnum) abort
  " Normalize
  if a:end_lnum < a:start_lnum
    let [a:start_lnum, a:end_lnum] = [a:end_lnum, a:start_lnum]
  endif

  " Grab slice
  let slice = getbufline(a:bufnr, a:start_lnum, a:end_lnum)
  if empty(slice)
    echoerr 'narrow: empty slice'
    return
  endif

  " Create acwrite buffer that shows only the slice
  enew
  let b:narrow_orig_buf = a:bufnr
  let b:narrow_start    = a:start_lnum
  let b:narrow_end      = a:end_lnum
  call setline(1, slice)

  setlocal buftype=acwrite bufhidden=wipe noswapfile
  let l:name = printf('[narrow] %s:%d-%d',
        \ fnamemodify(bufname(a:bufnr), ':t'), a:start_lnum, a:end_lnum)
  execute 'file ' . fnameescape(l:name)

  " Intercept :w
  augroup narrow_writeback | autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call narrow#write_back()
  augroup END
endfunction

function! narrow#write_back() abort
  if !exists('b:narrow_orig_buf') || !bufexists(b:narrow_orig_buf)
    echoerr 'narrow: original buffer disappeared'
    return
  endif
  let new = getline(1, '$')

  " Replace region (inclusive) inside original buffer
  let srow = b:narrow_start
  let erow = b:narrow_end
  call setbufline(b:narrow_orig_buf, srow, new)

  " Trim surplus if new slice shorter
  let removed = (erow - srow + 1) - len(new)
  if removed > 0
    call deletebufline(b:narrow_orig_buf, srow + len(new), srow + len(new) + removed - 1)
  endif

  " Save original file
  execute printf('noautocmd silent keepjumps keepalt buffer %d', b:narrow_orig_buf)
  silent keepjumps write
  execute 'buffer ' . bufnr('%')

  setlocal nomodified
  echom printf('narrow: wrote %d line(s) back', len(new))
endfunction
" }}}1
