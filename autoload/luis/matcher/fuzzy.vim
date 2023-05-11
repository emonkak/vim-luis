let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, context) abort dict 
  if a:context.pattern != ''
    let [candidates, positions, scores] =
    \ matchfuzzypos(a:candidates, a:context.pattern, { 'key': 'word' })
    let a:context._positions = positions
    let a:context._scores = scores
  else
    let candidates = a:candidates
    let a:context._positions = []
    let a:context._scores = []
  endif
  return candidates
endfunction

function! s:Matcher.normalize_candidate(candidate, index, context) abort dict 
  let a:candidate.luis_match_pos = get(a:context._positions, a:index, 0)
  let a:candidate.luis_match_score = get(a:context._scores, a:index, 0)
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
  if a:x.luis_match_pos != a:y.luis_match_pos
    if a:x.luis_match_score > a:y.luis_match_score
      return -1
    elseif a:x.luis_match_score < a:y.luis_match_score
      return 1
    endif
  endif
  if a:x.word < a:y.word
    return -1
  elseif a:x.word > a:y.word
    return 1
  endif
  return 0
endfunction

let g:luis#matcher#fuzzy#export = s:Matcher
