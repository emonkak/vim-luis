let s:Matcher = {}

function! s:Matcher.match_candidates(candidates, pattern, limit) abort dict 
  if a:pattern == ''
    let candidates = a:limit >= 0 ? a:candidates[:a:limit] : a:candidates
    call map(candidates, 's:normalize(v:val, 0, 0)')
  else
    let options = a:limit >= 0
    \           ? {'key': 'word', 'limit': a:limit }
    \           : {'key': 'word'}
    let [candidates, positions, scores] =
    \   matchfuzzypos(a:candidates, a:pattern, options)
    call map(candidates,
    \        's:normalize(v:val, positions[v:key], scores[v:key])')
  endif
  call sort(candidates, 's:compare')
  return candidates
endfunction

function! s:compare(x, y) abort
  if a:x.luis_sort_priority < a:y.luis_sort_priority
    return -1
  elseif a:x.luis_sort_priority > a:y.luis_sort_priority
    return 1
  endif
  if a:x.luis_match_position != a:y.luis_match_position
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

function! s:normalize(candidate, position, score) abort
  let a:candidate.equal = 1
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  if !has_key(a:candidate, 'luis_sort_priority')
    let a:candidate.luis_sort_priority = 0
  endif
  let a:candidate.luis_match_position = a:position
  let a:candidate.luis_match_score = a:score
  return a:candidate
endfunction

let g:luis#matcher#fuzzy#export = s:Matcher
