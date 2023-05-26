if !exists('g:luis#ui#default_matcher')
  let g:luis#ui#default_matcher = exists('*matchfuzzypos')
  \                             ? luis#matcher#fuzzy_native#import()
  \                             : luis#matcher#fuzzy#import()
endif

if !exists('g:luis#ui#default_comparer')
  let s:DefaultComparer = {}

  function! s:DefaultComparer.compare(first, second) abort dict
    let first_sp = get(a:first, 'luis_sort_priority', 0)
    let second_sp = get(a:second, 'luis_sort_priority', 0)

    if first_sp != second_sp
      return second_sp - first_sp
    endif

    if a:first.word < a:second.word
      return -1
    elseif a:first.word > a:second.word
      return 1
    endif

    return 0
  endfunction

  let g:luis#ui#default_comparer = s:DefaultComparer
endif

function! luis#ui#acc_text(pattern, candidates, source) abort
  " ACC = Automatic Component Completion
  let sep = a:pattern[-1:]
  let components = split(a:pattern, sep, 1)

  if len(components) < 2
    echoerr 'luis: Assumption on ACC is failed: ' . string(components)
    return ''
  endif

  " Find a candidate which has the same components but the last 2 ones of
  " components. Because components[-1] is always empty and
  " components[-2] is almost imperfect name of a component.
  "
  " Example:
  "
  " (a) a:pattern ==# 'usr/share/m/',
  "     components ==# ['usr', 'share', 'm', '']
  "
  "     The 1st candidate prefixed with 'usr/share/' will be used for ACC.
  "     If 'usr/share/man/man1/' is found in this way,
  "     the completed text will be 'usr/share/man'.
  "
  " (b) a:pattern ==# 'u/'
  "     components ==# ['u', '']
  "
  "     The 1st candidate is alaways used for ACC.
  "     If 'usr/share/man/man1/' is found in this way,
  "     the completion text will be 'usr'.
  "
  " (c) a:pattern ==# 'm/'
  "     components ==# ['m', '']
  "
  "     The 1st candidate is alaways used for ACC.
  "     If 'usr/share/man/man1/' is found in this way,
  "     the completion text will be 'usr/share/man'.
  "     Because user seems to want to complete till the component which
  "     matches to 'm'.
  for candidate in a:candidates
    let candidate_components = split(candidate.word, '\V' . sep, 1)

    if len(components) == 2
      " OK - the case (b) or (c)
    elseif len(components) - 2 <= len(candidate_components)
      for i in range(len(components) - 2)
        if components[i] != candidate_components[i]
          break
        endif
      endfor
      if components[i] != candidate_components[i]
        continue
      endif
      " OK - the case (a)
    else
      continue
    endif

    if has_key(a:source, 'is_valid_for_acc')
    \  && !a:source.is_valid_for_acc(candidate)
      continue
    endif

    " Find the index of the last component to be completed.
    "
    " For example, with candidate ==# 'usr/share/man/man1':
    "   If components ==# ['u', '']:
    "     c == 2 - 2
    "     i == 0
    "     t ==# 'usr/share/man/man1'
    "            ^
    "   If components ==# ['m', '']:
    "     c == 2 - 2
    "     i == 10
    "     t ==# 'usr/share/man/man1'
    "                      ^
    "   If components ==# ['usr', 'share', 'm', '']:
    "     c == 4 - 2
    "     i == 0
    "     t ==# 'man/man1'
    "            ^
    " Prefix components are all of components but the last two ones.
    let count_of_prefix = len(components) - 2
    " Tail of candidate.word without 'prefix' component in components.
    let tail = join(candidate_components[count_of_prefix:], sep)
    " Pattern for the partially typed component = components[-2].
    let pattern = '\c' . s:make_skip_regexp(components[-2])

    let i = matchend(tail, pattern)
    if i < 0
      continue  " Try next one
    endif

    let j = stridx(tail, sep, i)
    if j >= 0
      " Several candidate_components are matched for ACC.
      let tail_index = -(len(tail) - j + 1)
      return candidate.word[:tail_index]
    else
      " All of candidate_components are matched for ACC.
      return candidate.word
    endif
  endfor

  return ''
endfunction

function! luis#ui#collect_candidates(session, pattern) abort
  let source = a:session.source
  let hook = a:session.hook
  let matcher = has_key(source, 'matcher')
  \           ? source.matcher
  \           : g:luis#ui#default_matcher
  let comparer = has_key(source, 'comparer')
  \            ? source.comparer
  \            : g:luis#ui#default_comparer
  let context = {
  \   'comparer': comparer,
  \   'matcher': matcher,
  \   'pattern': a:pattern,
  \   'session': a:session,
  \ }

  let normalizers = []

  if has_key(matcher, 'normalize_candidate')
    call add(normalizers, matcher)
  endif
  if has_key(hook, 'normalize_candidate')
    call add(normalizers, hook)
  endif
  if has_key(a:session, 'normalize_candidate')
    call add(normalizers, a:session)
  endif

  let candidates = source.gather_candidates(context)
  let candidates = matcher.filter_candidates(candidates, context)
  if len(normalizers) > 0
    for i in range(len(candidates))
      for normalizer in normalizers
        let candidates[i] = normalizer.normalize_candidate(
        \   candidates[i],
        \   i,
        \   context
        \ )
      endfor
    endfor
  endif
  let candidates = matcher.sort_candidates(candidates, context)

  return candidates
endfunction

function! s:make_skip_regexp(s) abort
  " 'abc' ==> '\Va*b*c'
  " '\!/' ==> '\V\\*!*/'
  " Here '*' means '\.\{-}'
  let [init, last] = [a:s[:-2], a:s[-1:]]
  return '\V'
  \    . substitute(escape(init, '\'), '\%(\\\\\|[^\\]\)\zs', '\\.\\{-}', 'g')
  \    . escape(last, '\')
endfunction
