function! luis#matcher#substring#import() abort
  return s:Matcher
endfunction

let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, context) abort dict
  if a:context.pattern != ''
    return filter(
    \   copy(a:candidates),
    \   'stridx(v:val.word, a:context.pattern) >= 0'
    \ )
  else
    return a:candidates
  endif
endfunction

function! s:Matcher.sort_candidates(candidates, context) abort dict
  return sort(a:candidates, a:context.comparer.compare, a:context.comparer)
endfunction
