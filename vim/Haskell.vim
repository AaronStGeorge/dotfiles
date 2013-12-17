" Tab specific option
set tabstop=8                   "A tab is 8 spaces
set expandtab                   "Always uses spaces instead of tabs
set softtabstop=4               "Insert 4 spaces when tab is pressed
set shiftwidth=4                "An indent is 4 spaces
set smarttab                    "Indent instead of tab at start of line
set shiftround                  "Round spaces to nearest shiftwidth multiple
set nojoinspaces                "Don't convert spaces to tabs



" create section with --s command
let s:width = 80

function! HaskellModuleSection(...)
	    let name = 0 < a:0 ? a:1 : inputdialog("Section name: ")

		     return  repeat('-', s:width) . "\n"
			      \       . "--  " . name . "\n"
			      \       . "\n"

		  endfunction

		  nmap <silent> --s "=HaskellModuleSection()<CR>gp
