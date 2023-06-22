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
    return copy(a:candidates)
  endif
endfunction

function! s:Matcher.sort_candidates(candidates, context) abort dict
  let comparer = a:context.session.comparer
  return sort(a:candidates, comparer.compare_candidates, comparer)
endfunction
