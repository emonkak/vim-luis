let s:Matcher = {}

function! s:Matcher.match_candidates(candidates, pattern, source, limit) abort dict 
  if a:pattern == ''
    let candidates = a:limit >= 0 ? a:candidates[:a:limit] : a:candidates
    call map(candidates, 's:normalize(v:val, a:source, [], 0)')
  else
    let options = a:limit >= 0
    \           ? {'key': 'word', 'limit': a:limit }
    \           : {'key': 'word'}
    let [candidates, positions, scores] =
    \   matchfuzzypos(a:candidates, a:pattern, options)
    call map(candidates,
    \        's:normalize(v:val, a:source, positions[v:key], scores[v:key])')
  endif
  call sort(candidates, function('s:compare'))
  return candidates
endfunction

function! s:compare(x, y) abort
  if a:x.ku__sort_priority < a:y.ku__sort_priority
    return -1
  elseif a:x.ku__sort_priority > a:y.ku__sort_priority
    return 1
  endif
  if a:x.ku__matching_position != a:y.ku__matching_position
    if a:x.ku__matching_score > a:y.ku__matching_score
      return -1
    elseif a:x.ku__matching_score < a:y.ku__matching_score
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

function! s:normalize(candidate, source, position, score) abort
  let a:candidate.equal = 1
  let a:candidate.ku__matching_position = a:position
  let a:candidate.ku__matching_score = a:score
  if !has_key(a:candidate, 'ku__sort_priority')
    let a:candidate.ku__sort_priority = 0
  endif
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  let a:candidate.user_data.ku__completed_p = 1
  let a:candidate.user_data.ku__source = a:source
  return a:candidate
endfunction

let g:ku#matcher#fuzzy#export = s:Matcher
