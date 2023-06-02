function! luis#comparer#default#import() abort
  return s:Comparer
endfunction

let s:Comparer = {}

function! s:Comparer.compare_candidates(first, second) abort dict
  return a:first.luis_sort_priority != a:second.luis_sort_priority
  \      ? a:second.luis_sort_priority - a:first.luis_sort_priority
  \      : a:first.word < a:second.word
  \      ? -1
  \      : a:first.word > a:second.word
  \      ? 1
  \      : 0
endfunction

function! s:Comparer.normalize_candidate(candidate, index, context) abort dict
  if !has_key(a:candidate, 'luis_sort_priority')
    let a:candidate.luis_sort_priority = 0
  endif
  return a:candidate
endfunction
