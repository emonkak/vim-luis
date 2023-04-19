let s:Matcher = {}

function! s:Matcher.match_candidates(candidates, pattern, options)
  let candidates = a:candidates
  call map(candidates, 's:normalize(v:val, a:pattern)')
  call filter(candidates, 'v:val.luis_match_score > 0')
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
  if a:x.luis_match_score > a:y.luis_match_score
    return -1
  elseif a:x.luis_match_score < a:y.luis_match_score
    return 1
  endif
  if a:x.word < a:y.word
    return -1
  elseif a:x.word > a:y.word
    return 1
  endif
  return 0
endfunction

function! s:normalize(candidate, pattern) abort
  let a:candidate.equal = 1
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  if !has_key(a:candidate, 'luis_sort_priority')
    let a:candidate.luis_sort_priority = 0
  endif
  let a:candidate.luis_match_score = s:score(a:candidate.word, a:pattern)
  return a:candidate
endfunction

function! s:score(word, pattern) abort
  let pattern_len = len(a:pattern)
  if pattern_len == 0
    " Return base score.
    return 9000
  endif

  let word_len = len(a:word)
  if word_len < pattern_len  
    " Pattern never matches to word.
    return 0
  endif

  let word = toupper(a:word)
  let pattern = toupper(a:pattern)

  for pattern_offset in range(pattern_len, 1, -1)
    let pattern_head = pattern[:pattern_offset - 1] 
    let ignored_text_index = stridx(word, pattern_head)
    if ignored_text_index >= 0
      let rest_word = word[pattern_offset + ignored_text_index:]
      let rest_pattern = pattern[pattern_offset:]
      let rest_score = s:score(rest_word, rest_pattern)
      if rest_score > 0
        return (pattern_offset * 10000 + len(rest_word) * rest_score)
        \      / word_len
      endif
    endif
  endfor

  " Pattern doesn't match to word.
  return 0
endfunction

let g:luis#matcher#smart#export = s:Matcher
