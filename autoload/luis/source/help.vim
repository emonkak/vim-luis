function! luis#source#help#import() abort
  return s:Source
endfunction

let s:Source = {
\   'name': 'help',
\   'default_kind': luis#kind#help#import(),
\   'matcher': luis#matcher#through#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return map(
  \   getcompletion(a:context.pattern, 'help'),
  \   '{ "word": v:val }'
  \ )
endfunction
