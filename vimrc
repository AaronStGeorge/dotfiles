"==== set up Vundle and plugins
set nocompatible              " be iMproved
filetype off                  " required for initializing Vundle

"from: http://www.erikzaadi.com/2012/03/19/auto-installing-vundle-from-your-vimrc/
" Setting up Vundle - the vim plugin bundler
let iCanHazVundle=1
let vundle_readme=expand('~/.vim/bundle/vundle/README.md')
if !filereadable(vundle_readme)
	echo "Installing Vundle.."
	echo ""
	silent !mkdir -p ~/.vim/bundle
	silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
	let iCanHazVundle=0
endif
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'
Bundle 'scrooloose/syntastic'
Bundle 'altercation/vim-colors-solarized'
Bundle 'scrooloose/nerdtree'
Bundle 'kien/ctrlp.vim'
Bundle 'tpope/vim-fugitive'
Bundle 'christoomey/vim-tmux-navigator'
Bundle 'bling/vim-airline'
Bundle 'edkolev/tmuxline.vim'
Bundle 'Shougo/neocomplete.vim'
"HTML
Bundle 'mattn/emmet-vim'
Bundle 'vim-scripts/closetag.vim'
"JavaScript
Bundle 'jelera/vim-javascript-syntax'
Bundle 'pangloss/vim-javascript'
Bundle 'maksimr/vim-jsbeautify'
Bundle 'einars/js-beautify'
"Python
Bundle 'alfredodeza/pytest.vim'
"Go
Bundle 'fatih/vim-go'

if iCanHazVundle == 0
	echo "Installing Bundles, please ignore key map error messages"
	echo ""
	:BundleInstall
endif
" Setting up Vundle - the vim plugin bundler end

filetype plugin on	"allow language specific options in separate files
filetype indent on	"allow language specific options in separate files

"==== neocompleate
"" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ neocomplete#start_manual_complete()
function! s:check_back_space() "{{{
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction"}}}


"==== map keys
"map F9 to toggle NERDTree in directory of file in current buffer
map <F9>  :execute '  NERDTreeToggle' . expand('%:p:h') <CR>
"map F10 to SyntasticToggleMode
map <F10>  :execute 'SyntasticToggleMode'<CR>
"remap :tabnew to open NERDTree as well as new tab
cabbrev tabnew :tabnew<CR>:NERDTree<CR>
map <C-t> :tabnew<CR>	"map C-t to :tabnew
let mapleader = "\<space>"


"vim-airline"
let g:airline#extensions#tabline#enabled = 0
let g:airline_section_y = ""
let g:airline_section_x = ""
" Don't show seperators
let g:airline_left_sep=''
let g:airline_right_sep=''
let g:tmuxline_powerline_separators = 0


"==== restore cursor position
autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif


"==== js-beautify stuff
autocmd FileType javascript noremap <buffer>  <C-f> :call JsBeautify()<cr>
" for html
autocmd FileType html noremap <buffer> <C-f> :call HtmlBeautify()<cr>
" for css or scss
autocmd FileType css noremap <buffer> <C-f> :call CSSBeautify()<cr>


"pytest
nmap <silent><Leader>f <Esc>:Pytest file<CR>
nmap <silent><Leader>c <Esc>:Pytest class<CR>
nmap <silent><Leader>m <Esc>:Pytest method<CR>
nmap <silent><Leader>F <Esc>:Pytest file verbose<CR>
nmap <silent><Leader>C <Esc>:Pytest class verbose<CR>
nmap <silent><Leader>M <Esc>:Pytest method verbose<CR>


"==== Syntastic Setup
let g:syntastic_mode_map = { 'mode': 'active', 'active_filetypes': [],'passive_filetypes': ['html'] }
let g:syntastic_python_checkers=['pyflakes']	"set python cheker to pyflakes
let g:syntastic_ruby_checkers=['mri']
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_error_signs = 1


"==== color scheme
syntax enable
set background=dark
colorscheme solarized


"==== miscellaneous
set nu				"adds line numbers
set mouse=a			"use mouse in all modes
set scrolloff=2 		"keep at least 2 lines around your cursor at all times
set smarttab  	               	"smart tabbing - ex. automatic tab in for loop
set clipboard=unnamed         	"use the system clipboard
set laststatus=2              	"always show status bar
set backspace=indent,eol,start  "allows backspace to consume anything
set timeoutlen=200
"scroll down in SuperTab
let g:SuperTabDefaultCompletionType = "<c-n>"
" highlight the status bar when in insert mode
"highlight StatusLine   ctermbg=254 ctermfg=235
"if version >= 700
"	au InsertEnter * hi StatusLine ctermfg=33  ctermbg=254
"	au InsertLeave * hi StatusLine ctermbg=254  ctermfg=235
"endif
" Source the vimrc file after saving it
if has("autocmd")
	autocmd bufwritepost vimrc source $MYVIMRC
endif
"key mappings for easy navigation between splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
" Set this to the name of your terminal (term should supports mouse codes)
set ttymouse=xterm2
" Remove trailing whitespace on save
autocmd FileType python autocmd BufWritePre <buffer> :%s/\s\+$//e


"==== NERDTree stuff
let NERDTreeShowBookmarks=1	"always show bookmarks in NERDTree
let NERDTreeQuitOnOpen=1	"quit NERDTree after file is opened


"==== searching
set incsearch 			"incremental searching
set ignorecase 			"ignores case when searching
set smartcase  			"only ignore case when search is only lower case letters
set hlsearch 			"highlight searches
"press return to temporarily get out of the highlighted search
nnoremap <silent> <CR> :nohlsearch<CR><CR>


"==== functions
"if tabstop is 2 set it to 4 and update statusline, and vice versa
function! SetTabstop()
	if &ts == 2
		setlocal tabstop=4
		setlocal shiftwidth=4
		setlocal softtabstop=4
		setlocal expandtab
		let g:airline_section_y = "tab=4"
	else
		setlocal tabstop=2
		setlocal shiftwidth=2
		setlocal softtabstop=2
		setlocal expandtab
		let g:airline_section_y = "tab=2"
	endif
	AirlineRefresh
endfunction
