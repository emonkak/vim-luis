let s:Matcher = {}

function! s:Matcher.match_candidates(candidates, pattern, options) abort dict 
  let candidates = copy(a:candidates)
  if a:pattern != ''
    call filter(candidates, 'stridx(v:val.word, a:pattern) >= 0')
  endif
  call map(candidates, 's:normalize(v:val)')
  call sort(candidates, 's:compare')
  if has_key(a:options, 'limit')
    let candidates = candidates[:a:options.limit]
  endif
  return candidates
endfunction

function! s:compare(x, y) abort
  if a:x.luis_sort_priority < a:y.luis_sort_priority
    return -1
  elseif a:x.luis_sort_priority > a:y.luis_sort_priority
    return 1
  endif
  if a:x.word > a:y.word
    return 1
  elseif a:x.word < a:y.word
    return -1
  endif
  return 0
endfunction

function! s:normalize(candidate) abort
  let a:candidate.equal = 1
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  if !has_key(a:candidate, 'luis_sort_priority')
    let a:candidate.luis_sort_priority = 0
  endif
  return a:candidate
endfunction

let g:luis#matcher#exact#export = s:Matcher
