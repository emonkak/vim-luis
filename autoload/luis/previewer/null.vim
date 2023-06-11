function! luis#previewer#null#import() abort
  return s:Previewer
endfunction

let s:Previewer = {}

function! s:Previewer.close() abort dict
endfunction

function! s:Previewer.bounds() abort dict
  return { 'row': 0, 'col': 0, 'width': 0, 'height': 0 }
endfunction

function! s:Previewer.is_active() abort dict
  return 0
endfunction

function! s:Previewer.open_buffer(bufnr, bounds, hints) abort dict
endfunction

function! s:Previewer.open_text(lines, bounds, hints) abort dict
endfunction
