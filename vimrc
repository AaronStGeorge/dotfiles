set nu				"adds line numbers

set incsearch 			"incremental searching

set ignorecase 			"ignores case when searching
set smartcase  			"only ignore case when search is only lower case letters

set scrolloff=2 		"keep at least 2 lines around your cursor at all times

set wildmode=longest,list,full  "set bash like tab completion
set wildmenu 			"return list after second tab hit if there are multiple tab completes available 

set spell			"turns on spell checker 

"Note/: it would probably be cooler to set up an install script so I could put these python commands in 
"	a ~/.vim/ftplugin/python.vim file ( http://henry.precheur.org/vim/python.html ) 
autocmd FileType python set tabstop=4|set softtabstop=4|set shiftwidth=4|set textwidth=80|set smarttab|set expandtab
