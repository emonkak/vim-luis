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
    let candidates = copy(a:candidates)
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
  return sort(a:candidates, 's:compare', a:context.session.comparer)
endfunction

function! s:compare(first, second) abort dict
  return a:first.luis_match_priority != a:second.luis_match_priority
  \      ? a:first.luis_match_priority - a:second.luis_match_priority
  \      : a:first.luis_match_positions != a:second.luis_match_positions
  \        && a:first.luis_match_score != a:second.luis_match_score
  \      ? a:second.luis_match_score - a:first.luis_match_score
  \      : self.compare_candidates(a:first, a:second)
endfunction
