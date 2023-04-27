let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, args) abort dict 
  let candidates = a:candidates
  if a:args.pattern != ''
    let candidates = filter(
    \   copy(candidates),
    \   'stridx(v:val.word, a:args.pattern) >= 0'
    \ )
  endif
  return candidates
endfunction

function! s:Matcher.normalize_candidate(candidate, index, args) abort dict 
  return a:candidate
endfunction

function! s:Matcher.sort_candidates(candidates, args) abort dict
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

let g:luis#matcher#exact#export = s:Matcher
