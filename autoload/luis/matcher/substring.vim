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

function! s:Matcher.normalize_candidate(candidate, index, context) abort dict
  if !has_key(a:candidate, 'luis_sort_priority')
    let a:candidate.luis_sort_priority = 0
  endif
  return a:candidate
endfunction

function! s:Matcher.sort_candidates(candidates, context) abort dict
  return sort(a:candidates, 's:compare')
endfunction

function! s:compare(x, y) abort
  if a:x.luis_sort_priority < a:y.luis_sort_priority
    return -1
  elseif a:x.luis_sort_priority > a:y.luis_sort_priority
    return 1
  endif
  if a:x.word > a:y.word
    return 1
  elseif a:x.word < a:y.word
    return -1
  endif
  return 0
endfunction
