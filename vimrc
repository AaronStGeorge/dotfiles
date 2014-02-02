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
"Add your bundles here
Bundle 'Syntastic' 
Bundle 'altercation/vim-colors-solarized'
Bundle 'scrooloose/nerdtree'
Bundle 'Lokaltog/vim-easymotion'
Bundle 'davidhalter/jedi-vim'
Bundle 'ervandew/supertab'
if iCanHazVundle == 0
	echo "Installing Bundles, please ignore key map error messages"
	echo ""
	:BundleInstall
endif
" Setting up Vundle - the vim plugin bundler end

filetype plugin indent on	"allow language specific options in separate files


"==== map keys
"map F9 to toggle NERDTree in directory of file in current buffer
map <F9>  :execute '  NERDTreeToggle' . expand('%:p:h') <CR>
"remap :tabnew to open NERDTree as well as new tab
cabbrev tabnew :tabnew<CR>:NERDTree<CR>
map <C-t> :tabnew<CR>	"map C-t to :tabnew
let mapleader="\<space>"


"==== Syntastic Setup
let g:syntastic_mode_map = { 'mode': 'active',
			   \ 'active_filetypes': [],
			   \ 'passive_filetypes': ['html'] }
let g:syntastic_python_checkers=['pyflakes']	"set python cheker to pyflakes

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
let NERDTreeShowBookmarks=1	"always show bookmarks in NERDTree
let NERDTreeQuitOnOpen=1	"quit NERDTree after file is opened
"scroll down in SuperTab
let g:SuperTabDefaultCompletionType = "<c-n>"
" highlight the status bar when in insert mode
highlight StatusLine   ctermbg=254 ctermfg=235
if version >= 700
	au InsertEnter * hi StatusLine ctermfg=33  ctermbg=254
	au InsertLeave * hi StatusLine ctermbg=254  ctermfg=235
endif


"==== searching
set incsearch 			"incremental searching
set ignorecase 			"ignores case when searching
set smartcase  			"only ignore case when search is only lower case letters
