let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, context) abort dict
  let candidates = []
  for candidate in a:candidates
    let score = s:score(candidate.word, a:context.pattern)
    if score > 0.0
      let candidate.luis_smart_score = score
      call add(candidates, candidate)
    endif
  endfor
  return candidates
endfunction

function! s:Matcher.normalize_candidate(candidate, index, context) abort dict 
  return a:candidate
endfunction

function! s:Matcher.sort_candidates(candidates, context) abort dict
  return sort(a:candidates, 's:compare')
endfunction

function! s:compare(x, y) abort
  if a:x.luis_sort_priority < a:y.luis_sort_priority
    return -1
  elseif a:x.luis_sort_priority > a:y.luis_sort_priority
    return 1
  endif
  if a:x.luis_smart_score > a:y.luis_smart_score
    return -1
  elseif a:x.luis_smart_score < a:y.luis_smart_score
    return 1
  endif
  if a:x.word < a:y.word
    return -1
  elseif a:x.word > a:y.word
    return 1
  endif
  return 0
endfunction

function! s:score(word, pattern) abort
  let pattern_len = len(a:pattern)
  if pattern_len == 0
    " Return base score.
    return 0.9
  endif

  let word_len = len(a:word)
  if word_len < pattern_len  
    " Pattern never matches to word.
    return 0.0
  endif

  let word = toupper(a:word)
  let pattern = toupper(a:pattern)

  for pattern_index in range(pattern_len, 1, -1)
    let pattern_head = pattern[:pattern_index - 1] 
    let ignored_text_index = stridx(word, pattern_head)
    if ignored_text_index >= 0
      let rest_word = word[pattern_index + ignored_text_index:]
      let rest_pattern = pattern[pattern_index:]
      let rest_score = s:score(rest_word, rest_pattern)
      if rest_score > 0.0
        return (pattern_index * 1.0 + len(rest_word) * rest_score) / word_len
      else
        break
      endif
    endif
  endfor

  " Pattern doesn't match to word.
  return 0.0
endfunction

let g:luis#matcher#smart#export = s:Matcher
