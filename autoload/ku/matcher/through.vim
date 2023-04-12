let s:Matcher = {}

function! s:Matcher.match_candidates(candidates, pattern, source, limit) abort dict
  let candidates = a:limit >= 0 ? a:candidates[:a:limit] : a:candidates
  return map(candidates, 's:normalize(v:val, a:source)')
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

let g:ku#matcher#through#export = s:Matcher
