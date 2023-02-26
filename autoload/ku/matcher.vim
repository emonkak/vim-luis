" ku: matcher
" Variables  "{{{1

let g:ku#matcher#fuzzy = {
\   'match_candidates': function('ku#matcher#fuzzy_match')
\ }

let g:ku#matcher#raw = {
\   'match_candidates': function('ku#matcher#raw_match')
\ }

if !exists('g:ku#matcher#default')
  let g:ku#matcher#default = g:ku#matcher#fuzzy
endif








" Interface  "{{{1
function! ku#matcher#fuzzy_match(candidates, pattern, source, limit) abort  "{{{2
  if a:pattern == ''
    let candidates = a:limit >= 0
    \              ? a:candidates[:a:limit]
    \              : a:candidates
    let candidates = map(
    \   candidates,
    \   's:normalize_with_score(v:val, a:source, [], 0)'
    \ )
  else
    let options = a:limit >= 0
    \           ? {'key': 'word', 'limit': a:limit }
    \           : {'key': 'word'}
    let [candidates, positions, scores] =
    \   matchfuzzypos(a:candidates, a:pattern, options)
    let candidates = map(
    \   candidates,
    \   's:normalize_with_score(v:val,
    \                           a:source,
    \                           positions[v:key],
    \                           scores[v:key])'
    \ )
  endif
  let candidates = sort(candidates, function('s:compare_candidates'))
  return candidates
endfunction



function! ku#matcher#raw_match(candidates, pattern, source, limit) abort  "{{{2
  let candidates = a:limit >= 0 ? a:candidates[:a:limit] : a:candidates
  return map(candidates, 's:normalize(v:val, a:source)')
endfunction








" Misc.  "{{{1
function! s:compare_candidates(x, y) abort  "{{{2
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




function! s:normalize(candidate, source) abort  "{{{2
  let a:candidate.equal = 1
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  let a:candidate.user_data.ku__completed_p = 1
  let a:candidate.user_data.ku__source = a:source
  return a:candidate
endfunction




function! s:normalize_with_score(candidate, source, position, score) abort  "{{{2
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








" __END__  "{{{1
" vim: foldmethod=marker
