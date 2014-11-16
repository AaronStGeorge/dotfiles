setlocal tabstop=2
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal expandtab
setlocal textwidth=80
setlocal colorcolumn=81   "set a vertical line at 80 characters

" display how many spaces a tab is in status line
let g:airline_section_y = "tab=2"

" collapse vim-airline section y at 75 characters
let g:airline#extensions#default#section_truncate_width = {'y': 75}
