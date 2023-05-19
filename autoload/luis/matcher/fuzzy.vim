function! luis#matcher#fuzzy#import() abort
  return s:Matcher
endfunction

let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, context) abort dict
  let candidates = []
  for candidate in a:candidates
    let [score, start_pos, end_pos] = s:score(candidate.word, a:context.pattern)
    if score > 0.0
      let candidate.luis_match_score = float2nr(round(score * 1000))
      let candidate.luis_match_start_pos = start_pos
      let candidate.luis_match_end_pos = end_pos
      call add(candidates, candidate)
    endif
  endfor
  return candidates
endfunction

function! s:Matcher.normalize_candidate(candidate, index, context) abort dict
  if !has_key(a:candidate, 'luis_sort_priority')
    let a:candidate.luis_sort_priority = 0
  endif
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
  if a:x.luis_match_start_pos != a:y.luis_match_start_pos
  \  || a:x.luis_match_end_pos != a:y.luis_match_end_pos
    if a:x.luis_match_score > a:y.luis_match_score
      return -1
    elseif a:x.luis_match_score < a:y.luis_match_score
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

function! s:score(word, pattern) abort
  let pattern_len = len(a:pattern)
  if pattern_len == 0
    " Return base score.
    return [0.9, -1, -1]
  endif

  let word_len = len(a:word)
  if word_len < pattern_len
    " Pattern never matches to word.
    return [0.0, -1, -1]
  endif

  let word = toupper(a:word)
  let pattern = toupper(a:pattern)

  for pattern_index in range(pattern_len, 1, -1)
    let pattern_head = pattern[:pattern_index - 1]
    let ignored_text_index = stridx(word, pattern_head)
    if ignored_text_index >= 0
      let rest_word = word[pattern_index + ignored_text_index:]
      let rest_pattern = pattern[pattern_index:]
      let [rest_score, rest_start_pos, rest_end_pos] =
      \   s:score(rest_word, rest_pattern)
      if rest_score > 0.0
        let score =
        \   (pattern_index * 1.0 + len(rest_word) * rest_score) / word_len
        let start_pos = ignored_text_index
        let end_pos = ignored_text_index + pattern_index + rest_end_pos
        return [score, start_pos, end_pos]
      else
        break
      endif
    endif
  endfor

  " Pattern doesn't match to word.
  return [0.0, -1, -1]
endfunction
