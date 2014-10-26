"if tabstop is 2 set it to 4 and update statusline, and vice versa
function SetTabstop()
  if &ts == 2
    setlocal tabstop=4
    setlocal shiftwidth=4
    setlocal softtabstop=4
    setlocal statusline=%f\ -\ FileType:\ %y\ -\ Tab=4
    setlocal expandtab
  else
    setlocal tabstop=2
    setlocal shiftwidth=2
    setlocal softtabstop=2
    setlocal statusline=%f\ -\ FileType:\ %y\ -\ Tab=2
    setlocal expandtab
  endif
endfunction

"bind F8 key to SetTabstop
map <silent><F8> :call SetTabstop() <CR>
