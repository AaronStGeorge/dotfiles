set nu				"adds line numbers

set incsearch 			"incremental searching

set ignorecase 			"ignores case when searching
set smartcase  			"only ignore case when search is only lower case letters

set scrolloff=2 		"keep at least 2 lines around your cursor at all times

set smarttab  	                "smart tabbing - ex. automatic tab in for loop

set colorcolumn=81		"set a vertical line at 8o characters"

filetype plugin indent on

syntax on

set wildmode=longest,list,full  "set bash like tab completion
set wildmenu        			"return list after second tab hit if there are multiple tab completes available 

colorscheme molokai
set t_Co=256
hi Visual term=reverse ctermbg=6 guibg=DarkCyan

"sources: http://henry.precheur.org/vim/python.html | 
