function! luis#source#spell#new() abort
  return s:Source
endfunction

let s:Source = {
\   'name': 'spell',
\   'default_kind': luis#kind#text#import(),
\   'matcher': luis#matcher#through#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return map(spellsuggest(a:context.pattern), '{ "word": v:val }')
endfunction
