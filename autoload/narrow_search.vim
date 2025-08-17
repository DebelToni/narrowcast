" autoload/narrow_search.vim  {{{1
if exists('g:autoloaded_narrow_search') | finish | endif
let g:autoloaded_narrow_search = 1

" Simple patterns for ripgrep to find function/class definitions
" These are PCRE patterns, not Vim regex
let s:patterns = [
  \ '^\s*def\s+\w+\s*\(',
  \ '^\s*class\s+\w+',
  \ '^\s*function\s+\w+\s*\(',
  \ '^\s*const\s+\w+\s*=\s*(async\s+)?\(',
  \ '^\s*func\s+(\(\w+\)\s+)?\w+\s*\(',
  \ '^\s*(public|private|protected)?\s*\w+\s+\w+\s*\(',
  \ '^\s*(struct|enum)\s+\w+',
  \ '^\s*interface\s+\w+',
  \ '^\s*export\s+(function|class|const)\s+\w+'
  \]

" Use ripgrep to collect matches and return a list of lines:  file:lnum:preview
function! s:collect_candidates() abort
  let rg = executable('rg') ? 'rg' : ''
  if rg ==# ''
    echoerr 'narrow-search: ripgrep not found'
    return []
  endif

  " Build the ripgrep command with multiple -e patterns
  let cmd_parts = [rg, '-n', '--no-heading', '--color=never', '--type-add', "'code:*.{js,ts,py,go,java,c,cpp,h,hpp,swift,rs}'"]
  
  " Add each pattern as a separate -e flag
  for pattern in s:patterns
    call add(cmd_parts, '-e')
    call add(cmd_parts, shellescape(pattern))
  endfor
  
  " Add the search path (current directory)
  call add(cmd_parts, '.')
  
  let cmd = join(cmd_parts, ' ')
  
  " Execute and return results
  let results = systemlist(cmd)
  
  " Filter out binary file matches and other noise
  let filtered = []
  for line in results
    if line =~ '^[^:]*:[0-9]\+:'
      call add(filtered, line)
    endif
  endfor
  
  return filtered
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
  echo 'Searching for functions and classes...'
  let candidates = s:collect_candidates()
  if empty(candidates) 
    echo 'narrow-search: No functions or classes found in current directory'
    return 
  endif
  
  echo printf('Found %d matches', len(candidates))

  " 1. Check for fzf.vim (most common)
  if exists('*fzf#run') && (exists('g:loaded_fzf_vim') || exists('g:loaded_fzf'))
    function! s:fzf_sink(selected) abort
      if empty(a:selected) | return | endif
      " Handle both list and string input
      let line = type(a:selected) == type([]) ? a:selected[0] : a:selected
      call s:open_from_candidate(line)
    endfunction
    
    " Use fzf with preview if available
    let fzf_opts = {
      \ 'source': candidates,
      \ 'sink': function('s:fzf_sink'),
      \ 'options': ['--prompt', 'Narrow> ', '--preview-window', 'right:50%', '--ansi'],
      \ 'window': {'width': 0.9, 'height': 0.6}
    \ }
    
    " Try to use fzf#wrap if available for better integration
    if exists('*fzf#wrap')
      call fzf#run(fzf#wrap('narrow-search', fzf_opts))
    else
      call fzf#run(fzf_opts)
    endif
    return
  endif

  " 2. Telescope (Neovim only)
  if exists(':Telescope') && has('nvim')
    " Try to use Telescope with better error handling
    try
      lua << EOF
      local pickers = require('telescope.pickers')
      local finders = require('telescope.finders')
      local conf = require('telescope.config').values
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')
      
      local candidates = vim.fn['narrow_search#get_candidates']()
      
      pickers.new({}, {
        prompt_title = 'Narrow Search',
        finder = finders.new_table {
          results = candidates,
        },
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then
              vim.fn['narrow_search#open_candidate'](selection[1])
            end
          end)
          return true
        end,
      }):find()
EOF
    catch
      echo 'Telescope integration failed, falling back to quickfix'
    endtry
    return
  endif

  " 3. Quickfix fallback
  let qf = []
  for l in candidates
    let m = matchlist(l, '\v^(.+):(\d+):(.*)$')
    if len(m) >= 4
      call add(qf, {'filename': m[1], 'lnum': str2nr(m[2]), 'text': m[3]})
    endif
  endfor
  
  if !empty(qf)
    call setqflist(qf, 'r')
    copen
    echo 'Select an entry and press Enter, or use :NarrowHere'
  else
    echo 'narrow-search: Failed to parse results'
  endif
endfunction

" Helper functions for external access (used by Telescope integration)
function! narrow_search#get_candidates() abort
  return s:collect_candidates()
endfunction

function! narrow_search#open_candidate(candidate) abort
  call s:open_from_candidate(a:candidate)
endfunction
" }}}1
