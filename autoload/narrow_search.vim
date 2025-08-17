" autoload/narrow_search.vim  {{{1
if exists('g:autoloaded_narrow_search') | finish | endif
let g:autoloaded_narrow_search = 1

" List of filetypes we recognise and the regex that matches a definition.
let s:lang_defs = {
\ 'c'      : '\v^\s*(?:static\s+)?[A-Za-z_][A-Za-z0-9_]*\s+[A-Za-z_][A-Za-z0-9_]*\s*\(',
\ 'cpp'    : '\v^\s*(?:template.*>)?\s*(?:inline\s+)?[A-Za-z_][A-Za-z0-9_:<>~]*\s+[A-Za-z_][A-Za-z0-9_:<>~]*\s*\(',
\ 'python' : '\v^\s*def\s+\w+\s*\(',
\ 'java'   : '\v^\s*(public|private|protected)?\s*(class|interface|enum|void|static|\w+)\s+\w+\s*\(',
\ 'javascript' : '\v^\s*(function\s+\w+|\w+\s*=\s*function|\w+\s*:\s*function)',
\ 'typescript' : '\v^\s*(export\s+)?(function|class)\s+\w+',
\ 'go'     : '\v^\s*func\s+(\([^)]+\)\s*)?\w+\s*\(',
\ 'swift'  : '\v^\s*(class|struct|enum|func)\s+\w+',
\}

" Generate ripgrep pattern union of all definitions.
function! s:build_rg_pattern() abort
  return '\(' . join(values(s:lang_defs), '\|') . '\)'
endfunction

" Use ripgrep to collect matches and return a list of lines:  file:lnum:preview
function! s:collect_candidates() abort
  let rg = executable('rg') ? 'rg' : executable('ripgrep') ? 'ripgrep' : ''
  if rg ==# ''
    echoerr 'narrow-search: ripgrep not found'
    return []
  endif

  let pattern = s:build_rg_pattern()
  " -n line numbers, --no-heading, --color=never  ()
  let cmd = printf('%s -n --no-heading --color=never -e %s', rg, shellescape(pattern))
  return systemlist(cmd)
endfunction

" Parse 'file:lnum:content' and open narrow buffer
function! s:open_from_candidate(candidate) abort
  let parts = matchlist(a:candidate, '\v^(.+):(\d+):(.*)$')
  if len(parts) < 4 | return | endif
  let [file, lnum] = [parts[1], str2nr(parts[2])]
  execute 'edit ' . fnameescape(file)
  call narrow#open_range(bufnr('%'), lnum, lnum + 100)   " 100-line window as default
endfunction

" Picker: telescope (if available) else fzf (if available) else quickfix list
function! narrow_search#picker() abort
  let candidates = s:collect_candidates()
  if empty(candidates) | echo 'narrow-search: nothing found' | return | endif

  " 1. Telescope
  if exists(':Telescope') && has('nvim')
    call luaeval("require('telescope.pickers').new({}, require('telescope.finders').new_table{results=_A[1]}, require('telescope.conf').values).find()", candidates)
    " Selection handler from Lua back into Vimscript using Vim.fn
    augroup narrow_telescope | autocmd! | 
      \ autocmd User TelescopePreviewerLoaded nnoremap <silent><buffer> <CR> :call <SID>open_from_candidate(expand('<cword>'))<CR> |
    augroup END
    return
  endif

  " 2. fzf.vim
  if exists('*fzf#run')
    function! s:fzf_sink(lines) abort
      if empty(a:lines) | return | endif
      call s:open_from_candidate(a:lines[0])
    endfunction
    call fzf#run({'source': candidates, 'sink*': function('s:fzf_sink'), 'options': '--prompt "Narrow> "'})
    return
  endif

  " 3. Quickfix fallback
  let qf = []
  for l in candidates
    let m = matchlist(l, '\v^(.+):(\d+):(.*)$')
    call add(qf, {'filename': m[1], 'lnum': str2nr(m[2]), 'text': m[3]})
  endfor
  call setqflist(qf, 'r')
  copen
  echo 'Select an entry and run  :NarrowHere'
endfunction

" Command for quickfix fallback
command! NarrowHere call narrow#open_range(bufnr('%'), line('.'), line('.')+100)
" }}}1
