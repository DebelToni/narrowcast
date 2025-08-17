" autoload/narrow.vim  {{{1
if exists('g:autoloaded_narrow') | finish | endif
let g:autoloaded_narrow = 1

function! narrow#open_range(bufnr, start_lnum, end_lnum) abort
  " Normalize and bounds check
  let orig_buf = a:bufnr
  let start_lnum = a:start_lnum
  let end_lnum = a:end_lnum
  
  if end_lnum < start_lnum
    let [start_lnum, end_lnum] = [end_lnum, start_lnum]
  endif
  
  let last_line = getbufinfo(orig_buf)[0].linecount
  let start_lnum = max([1, min([start_lnum, last_line])])
  let end_lnum = max([1, min([end_lnum, last_line])])

  " Grab slice
  let slice = getbufline(orig_buf, start_lnum, end_lnum)
  if empty(slice)
    echoerr 'narrow: empty slice'
    return
  endif

  " Store original buffer's filetype and name
  let orig_ft = getbufvar(orig_buf, '&filetype')
  let orig_name = bufname(orig_buf)
  if orig_name == ''
    let orig_name = '[No Name]'
  else
    let orig_name = fnamemodify(orig_name, ':t')
  endif

  " Create new buffer for narrowed content
  enew
  let narrow_buf = bufnr('%')
  
  " Set buffer local variables for tracking
  let b:narrow_orig_buf = orig_buf
  let b:narrow_start_line = start_lnum
  let b:narrow_end_line = end_lnum
  
  " Insert the content
  call setline(1, slice)
  
  " Set filetype to match original for syntax highlighting
  if !empty(orig_ft)
    execute 'setlocal filetype=' . orig_ft
  endif
  
  " Configure buffer settings
  setlocal buftype=acwrite
  setlocal bufhidden=wipe
  setlocal noswapfile
  
  " Set a descriptive name with file extension for syntax
  let ext = fnamemodify(orig_name, ':e')
  if !empty(ext)
    let narrow_name = printf('[narrow] %s:%d-%d.%s', orig_name, start_lnum, end_lnum, ext)
  else
    let narrow_name = printf('[narrow] %s:%d-%d', orig_name, start_lnum, end_lnum)
  endif
  execute 'silent! file ' . fnameescape(narrow_name)

  " Set up marks for tracking the region (Vim doesn't have extmarks like Neovim)
  " We'll use buffer variables to track original positions
  
  " Intercept :w
  augroup narrow_writeback
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call narrow#write_back()
  augroup END
  
  " Mark buffer as unmodified initially
  setlocal nomodified
endfunction

function! narrow#write_back() abort
  " Check if original buffer still exists
  if !exists('b:narrow_orig_buf') || !bufexists(b:narrow_orig_buf)
    echoerr 'narrow: original buffer disappeared'
    return
  endif
  
  let orig_buf = b:narrow_orig_buf
  let start_line = b:narrow_start_line
  let end_line = b:narrow_end_line
  let narrow_buf = bufnr('%')
  
  " Get the new content from narrowed buffer
  let new_lines = getline(1, '$')
  
  " Calculate how many lines we're replacing
  let old_line_count = end_line - start_line + 1
  let new_line_count = len(new_lines)
  
  " Switch to original buffer to make changes
  let orig_winnr = bufwinnr(orig_buf)
  if orig_winnr == -1
    " Original buffer not in any window, we need to load it
    execute 'silent! keepjumps keepalt buffer ' . orig_buf
  else
    " Switch to the window containing the original buffer
    execute 'silent! keepjumps ' . orig_winnr . 'wincmd w'
  endif
  
  " Delete the old lines and insert new ones
  if old_line_count > 0
    execute 'silent! keepjumps ' . start_line . ',' . end_line . 'delete _'
  endif
  
  " Insert new lines at the right position
  if len(new_lines) > 0
    " Move to the line before where we want to insert (or line 0 if at start)
    let insert_line = start_line - 1
    if insert_line == 0
      " Special case: inserting at the beginning
      call append(0, new_lines)
    else
      call append(insert_line, new_lines)
    endif
  endif
  
  " Save the original buffer
  silent! write
  
  " Update the end line for this narrow buffer if lines changed
  let b:narrow_end_line = start_line + new_line_count - 1
  
  " Switch back to narrow buffer
  execute 'silent! buffer ' . narrow_buf
  
  " Mark narrowed buffer as unmodified
  setlocal nomodified
  
  " Show a message
  echom printf('narrow: wrote %d line(s) back to %s', new_line_count, fnamemodify(bufname(orig_buf), ':.'))
endfunction
" }}}1
