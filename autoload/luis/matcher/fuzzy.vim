function! luis#matcher#fuzzy#import() abort
  return s:Matcher
endfunction

let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, context) abort dict
  let candidates = []
  for candidate in a:candidates
    let [score, positions] = s:score(candidate.word, a:context.pattern, 0)
    if score > 0.0
      let candidate.luis_match_positions = positions
      if !has_key(candidate, 'luis_match_priority')
        let candidate.luis_match_priority = 0
      endif
      let candidate.luis_match_score = float2nr(round(score * 1000))
      call add(candidates, candidate)
    endif
  endfor
  return candidates
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

  return self.comparer.compare(a:first, a:second)
endfunction

function! s:score(word, pattern, offset) abort
  let pattern_len = len(a:pattern)
  if pattern_len == 0
    " Return the base score.
    return [0.9, []]
  endif

  let word_len = len(a:word)
  if word_len < pattern_len
    " Pattern never matches to the word.
    return [0.0, []]
  endif

  let word = toupper(a:word)
  let pattern = toupper(a:pattern)

  for pattern_index in range(pattern_len, 1, -1)
    let pattern_head = pattern[:pattern_index - 1]
    let ignored_text_index = stridx(word, pattern_head)
    if ignored_text_index >= 0
      let rest_word = word[pattern_index + ignored_text_index:]
      let rest_pattern = pattern[pattern_index:]
      let [rest_score, rest_positions] = s:score(
      \   rest_word,
      \   rest_pattern,
      \   a:offset + ignored_text_index + pattern_index,
      \ )
      if rest_score > 0.0
        let score =
        \   (pattern_index * 1.0 + len(rest_word) * rest_score) / word_len
        let positions = range(
        \   a:offset + ignored_text_index,
        \   a:offset + ignored_text_index + pattern_index - 1
        \ )
        let positions = extend(positions, rest_positions)
        return [score, positions]
      else
        break
      endif
    endif
  endfor

  " Pattern doesn't match to the word.
  return [0.0, []]
endfunction
