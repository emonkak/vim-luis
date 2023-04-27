let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, args) abort dict 
  if a:args.pattern != ''
    let [candidates, positions, scores] =
    \ matchfuzzypos(a:candidates, a:args.pattern, { 'key': 'word' })
    let a:args._positions = positions
    let a:args._scores = scores
  else
    let candidates = a:candidates
    let a:args._positions = []
    let a:args._scores = []
  endif
  return candidates
endfunction

function! s:Matcher.normalize_candidate(candidate, index, args) abort dict 
  let a:candidate.luis_fuzzy_pos = get(a:args._positions, a:index, 0)
  let a:candidate.luis_fuzzy_score = get(a:args._scores, a:index, 0)
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
  if a:x.luis_fuzzy_pos != a:y.luis_fuzzy_pos
    if a:x.luis_fuzzy_score > a:y.luis_fuzzy_score
      return -1
    elseif a:x.luis_fuzzy_score < a:y.luis_fuzzy_score
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
