# Narrow-Search

Portable Vim/Neovim plugin that lets you **narrow-edit** any slice of a file
*and* open slices straight from a fuzzy search across your project.

```vim
" Narrow the current function (visual mode)
vmap <leader>n :Narrow<CR>

" Fuzzy-search functions/classes across project
nnoremap <leader>N :NarrowSearch<CR>
```

Requires one of **Telescope.nvim** or **fzf.vim** (falls back to quickfix).
Hard-coded language regexes cover C/C++, Python, Java, JS/TS, Go, Swift.
No LSP necessary.

MIT-licensed.  See `:h narrow` for full docs.
