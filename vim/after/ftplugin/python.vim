setlocal tabstop=4
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal expandtab
setlocal textwidth=80
setlocal colorcolumn=81   "set a vertical line at 80 characters

" display how many spaces a tab is in status line
let g:airline_section_y = "tab=4"

" collapse vim-airline section y at 75 characters
let g:airline#extensions#default#section_truncate_width = {'y': 75}
