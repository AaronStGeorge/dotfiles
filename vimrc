set nocompatible		"sets compatible mode to off
set nu				"adds line numbers
set mouse=a			"use mouse in all modes
set scrolloff=2 		"keep at least 2 lines around your cursor at all times
set smarttab  	                "smart tabbing - ex. automatic tab in for loop


"==== searching
set incsearch 			"incremental searching
set ignorecase 			"ignores case when searching
set smartcase  			"only ignore case when search is only lower case letters


"==== plugins
filetype plugin on		"allow language specific options in separate files
syntax on
execute pathogen#infect()
map <F9> :NERDTreeToggle<CR>	"maps NERTgreeToggle to F2


"==== color scheme
colorscheme molokai
set t_Co=256
hi Visual term=reverse ctermbg=6 guibg=DarkCyan

"sources: http://henry.precheur.org/vim/python.html | 
