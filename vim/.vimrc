" Leader key
let mapleader=" "

" Save / Quit
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>
vnoremap <C-s> :w<CR>

nnoremap <C-q> :q<CR>
inoremap <C-q> <Esc>:q<CR>
vnoremap <C-q> :q<CR>

" Paste without losing selection
vnoremap p pgvy

" Movement in visual mode
vnoremap J jzz
vnoremap K kzz
vnoremap < <gv
vnoremap > >gv

" Movement in normal mode
nnoremap J jzz
nnoremap K kzz
nnoremap ; nzz
nnoremap ' Nzz

" Select all
nnoremap <leader>aa ggVG

" Yank whole buffer
nnoremap <leader>y mzggVGy`zzz

" Delete whole buffer
nnoremap <leader>D ggVGd

" Insert new lines quickly
nnoremap n o<Esc>
nnoremap N O<Esc>
nnoremap <leader>n i<CR><Esc>_

" Toggle wrap
nnoremap <leader>w :set wrap!<CR>
