function! luis#matcher#fuzzy_native#import() abort
  return s:Matcher
endfunction

let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, context) abort dict
  if a:context.pattern != ''
    let [candidates, positions, scores] =
    \   matchfuzzypos(a:candidates, a:context.pattern, { 'key': 'word' })
    let a:context._match_positions = positions
    let a:context._match_scores = scores
  else
    let candidates = a:candidates
    let a:context._match_positions = []
    let a:context._match_scores = []
  endif
  return candidates
endfunction

function! s:Matcher.normalize_candidate(candidate, index, context) abort dict
  let a:candidate.luis_match_positions = get(a:context._match_positions, a:index, [])
  if !has_key(a:candidate, 'luis_match_priority')
    let a:candidate.luis_match_priority = 0
  endif
  let a:candidate.luis_match_score = get(a:context._match_scores, a:index, 0)
  return a:candidate
endfunction

function! s:Matcher.sort_candidates(candidates, context) abort dict
  return sort(a:candidates, 's:compare', a:context)
endfunction

function! s:compare(first, second) abort dict
  let first_priority = a:first.luis_match_priority
  let second_priority = a:second.luis_match_priority

  if first_priority != second_priority
    return second_priority - first_priority
  endif

  if a:first.luis_match_positions != a:second.luis_match_positions
    let first_score = a:first.luis_match_score
    let second_score = a:second.luis_match_score

    if first_score != second_score
      return second_score - first_score
    endif
  endif

  return self.comparer.compare_candidates(a:first, a:second)
endfunction
