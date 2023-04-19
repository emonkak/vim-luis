function! luis#source#spell#new() abort
  return s:Source
endfunction

let s:Source = {
\   'name': 'spell',
\   'default_kind': g:luis#kind#text#export,
\   'matcher': g:luis#matcher#through#export,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return map(spellsuggest(a:pattern), '{ "word": v:val }')
endfunction
