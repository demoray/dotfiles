set history=1000
"filetype plugin indent on
"autocmd FileType text setlocal textwidth=78
set backspace=2
set autoindent
"set ruler
set ts=4
set shiftwidth=4
set smartindent
set expandtab

syn on
set background=dark
" syn on
map <C-J> <C-W>j<C-W>_
map <C-K> <C-W>k<C-W>_
set wmw=0
nmap <c-h> <c-w>h<c-w>_
nmap <c-l> <c-w>l<c-w>_

map \p i(<Esc>ea)<Esc>
map \c i{<Esc>ea}<Esc>

"copy and paste betweeen different vim sessions
nmap    _Y      :!echo ""> ~/.vi_tmp<CR><CR>:w! ~/.vi_tmp<CR>
vmap    _Y      :w! ~/.vi_tmp<CR>
nmap    _P      :r ~/.vi_tmp<CR>


map ,, :s/^/,/<CR>
map ,# :s/^/#/<CR>
map ,/ :s/^/\/\//<CR>
map ,> :s/^/> /<CR>
map ," :s/^/\"/<CR>
map ,' :s/^/\'/<CR>
map ,% :s/^/%/<CR>
map ,! :s/^/!/<CR>
map ,; :s/^/;/<CR>
map ,- :s/^/--/<CR>
map ,<TAB> :s/^/    /<CR>
map ,c :s/^\/\/\\|^--\\|^> \\|^[#"%!;]//<CR>

" wrapping comments
map ,* :s/^\(.*\)$/\/\* \1 \*\//<CR>
map ,( :s/^\(.*\)$/\(\* \1 \*\)/<CR>
map ,< :s/^\(.*\)$/<!-- \1 -->/<CR>
map ,d :s/^\([/(]\*\\|<!--\) \(.*\) \(\*[/)]\\|-->\)$/\2/<CR>
map ,h :s/^\(.*\)/<!-- \1 -->/<CR>

map <F3> ggVGg?
color desert


" vim -b : edit binary using xxd-format!
augroup Binary
	au!
	au BufReadPre  *.tif let &bin=1
	au BufReadPost *.tif if &bin | %!xxd
	au BufReadPost *.tif set ft=xxd | endif
	au BufWritePre *.tif if &bin | %!xxd -r
	au BufWritePre *.tif endif
	au BufWritePost *.tif if &bin | %!xxd
	au BufWritePost *.tif set nomod | endif
augroup END


autocmd FileType make setlocal noexpandtab


set nocompatible              " be iMproved, required
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Bundle 'matze/vim-tex-fold'
call vundle#end()            " required
filetype plugin indent on    " required

nnoremap <silent> <Space> @=(foldlevel('.')?'za':"\<Space>")<CR>
vnoremap <Space> zf
set directory=~/.vim/swap
