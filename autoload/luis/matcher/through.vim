let s:Matcher = {}

function! s:Matcher.match_candidates(candidates, pattern, limit) abort dict
  let candidates = a:limit >= 0 ? a:candidates[:a:limit] : a:candidates
  call map(candidates, 's:normalize(v:val)')
  return candidates
endfunction

function! s:normalize(candidate) abort
  let a:candidate.equal = 1
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  return a:candidate
endfunction

let g:luis#matcher#through#export = s:Matcher
