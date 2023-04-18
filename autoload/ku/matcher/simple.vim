let s:Matcher = {}

function! s:Matcher.match_candidates(candidates, pattern, limit) abort dict 
  let candidates = copy(a:candidates)
  if a:pattern != ''
    call filter(candidates, 'stridx(v:val.word, a:pattern) >= 0')
  endif
  call map(candidates, 's:normalize(v:val)')
  call sort(candidates, function('s:compare'))
  if a:limit >= 0
    let candidates = candidates[:a:limit]
  endif
  return candidates
endfunction

function! s:compare(x, y) abort
  if a:x.ku__sort_priority < a:y.ku__sort_priority
    return -1
  elseif a:x.ku__sort_priority > a:y.ku__sort_priority
    return 1
  elseif a:x.word ># a:y.word
    return 1
  endif
  return 0
endfunction

function! s:normalize(candidate) abort
  let a:candidate.equal = 1
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  if !has_key(a:candidate, 'ku__sort_priority')
    let a:candidate.ku__sort_priority = 0
  endif
  return a:candidate
endfunction

let g:ku#matcher#simple#export = s:Matcher
