" ku: matcher
" Variables  "{{{1

if !exists('g:ku#matcher#default')
  let g:ku#matcher#default = {
  \   'match_candidates': function('ku#matcher#fuzzy_match')
  \ }
endif

if !exists('g:ku#matcher#limit_candidates')
  let g:ku#matcher#limit_candidates = 1000
endif








" Interface  "{{{1
function! ku#matcher#raw_match(candidates, pattern, source) abort  "{{{2
  return map(a:candidates[:g:ku#matcher#limit_candidates],
  \          's:normalize_candidate(v:val, a:source)')
endfunction




function! ku#matcher#fuzzy_match(candidates, pattern, source) abort  "{{{2
  if a:pattern == ''
    let candidates = map(a:candidates[:g:ku#matcher#limit_candidates],
    \                    's:normalize_candidate(v:val, a:source)')
    let candidates = sort(candidates, function('s:compare_candidates'))
  else
    let [candidates, positions, scores] =
    \   matchfuzzypos(a:candidates,
    \                 a:pattern,
    \                 {'key': 'word', 'limit': g:ku#matcher#limit_candidates})
    let candidates = map(candidates,
    \                    's:normalize_fuzzy_candidate(v:val,
    \                                                 a:source,
    \                                                 positions[v:key],
    \                                                 scores[v:key])')
    let candidates = sort(candidates, function('s:compare_fuzzy_candidates'))
  endif
  return candidates
endfunction




" Misc.  "{{{1
function! s:normalize_fuzzy_candidate(candidate, source, position, score) abort  "{{{2
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  let a:candidate.user_data.ku__completed_p = 1
  let a:candidate.user_data.ku__source = a:source
  if !has_key(a:candidate, 'ku__sort_priority')
    let a:candidate.ku__sort_priority = 0
  endif
  let a:candidate.equal = 1
  let a:candidate.ku__matching_position = a:position
  let a:candidate.ku__matching_score = a:score
  return a:candidate
endfunction




function! s:normalize_candidate(candidate, source) abort  "{{{2
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  let a:candidate.user_data.ku__completed_p = 1
  let a:candidate.user_data.ku__source = a:source
  if !has_key(a:candidate, 'ku__sort_priority')
    let a:candidate.ku__sort_priority = 0
  endif
  let a:candidate.equal = 1
  return a:candidate
endfunction




function! s:compare_fuzzy_candidates(x, y) abort  "{{{2
  if a:x.ku__matching_position != a:y.ku__matching_position
    if a:x.ku__matching_score > a:y.ku__matching_score
      return -1
    endif
    if a:x.ku__matching_score < a:y.ku__matching_score
      return 1
    endif
  endif
  if a:x.ku__sort_priority < a:y.ku__sort_priority
    return -1
  endif
  if a:x.ku__sort_priority > a:y.ku__sort_priority
    return 1
  endif
  if a:x.word < a:y.word
    return -1
  endif
  if a:x.word > a:y.word
    return 1
  endif
  return 0
endfunction




function! s:compare_candidates(x, y) abort  "{{{2
  if a:x.ku__sort_priority < a:y.ku__sort_priority
    return -1
  endif
  if a:x.ku__sort_priority > a:y.ku__sort_priority
    return 1
  endif
  if a:x.word < a:y.word
    return -1
  endif
  if a:x.word > a:y.word
    return 1
  endif
  return 0
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
