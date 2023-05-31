if !exists('g:luis#ui#default_matcher')
  let g:luis#ui#default_matcher = exists('*matchfuzzypos')
  \                             ? luis#matcher#fuzzy_native#import()
  \                             : luis#matcher#fuzzy#import()
endif

if !exists('g:luis#ui#default_comparer')
  let s:DefaultComparer = {}

  function! s:DefaultComparer.compare_candidates(first, second) abort dict
    return a:first.luis_sort_priority != a:second.luis_sort_priority
    \      ? a:second.luis_sort_priority - a:first.luis_sort_priority
    \      : a:first.word < a:second.word
    \      ? -1
    \      : a:first.word > a:second.word
    \      ? 1
    \      : 0
  endfunction

  function! s:DefaultComparer.normalize_candidate(candidate, index, context) abort dict
    if !has_key(a:candidate, 'luis_sort_priority')
      let a:candidate.luis_sort_priority = 0
    endif
    return a:candidate
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
  let comparer = get(source, 'comparer', g:luis#ui#default_comparer)
  let matcher = get(source, 'matcher', g:luis#ui#default_matcher)
  let context = {
  \   'comparer': comparer,
  \   'matcher': matcher,
  \   'pattern': a:pattern,
  \   'session': a:session,
  \ }

  let normalizers = []

  if has_key(comparer, 'normalize_candidate')
    call add(normalizers, comparer)
  endif
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

function! luis#ui#detect_filetype(path, lines) abort
  if has('nvim')
    let _ =<< trim END
    vim.filetype.match({
      filename = vim.api.nvim_eval('a:path'),
      contents = vim.api.nvim_eval('a:lines'),
    }) or ''
END
    return luaeval(join(_, ''))
  else
    let temp_win = popup_create(a:lines, { 'hidden': 1 })
    let temp_bufnr = winbufnr(temp_win)
    try
      let command = 'doautocmd filetypedetect BufNewFile '
      \           . fnameescape(a:path)
      call win_execute(temp_win, command)
      return getbufvar(temp_bufnr, '&filetype')
    finally
      call popup_close(temp_win)
    endtry
  endif
endfunction

function! luis#ui#start_preview(session, preview_window, dimensions) abort
  let candidate = a:session.guess_candidate()
  let context = {
  \   'preview_window': a:preview_window,
  \   'session': a:session,
  \ }

  if has_key(a:session.source, 'on_preview')
    call a:session.source.on_preview(candidate, context)
  endif

  if has_key(a:session.hook, 'on_preview')
    call a:session.hook.on_preview(candidate, context)
  endif

  if has_key(candidate.user_data, 'preview_lines')
    let hints = s:preview_hints_from_candidate(candidate)
    call a:preview_window.open_text(
    \   candidate.user_data.preview_lines,
    \   a:dimensions,
    \   hints
    \ )
    return 1
  endif

  if has_key(candidate.user_data, 'preview_bufnr')
    let bufnr = candidate.user_data.preview_bufnr
    if bufloaded(bufnr)
      let hints = s:preview_hints_from_candidate(candidate)
      call a:preview_window.open_buffer(
      \   bufnr,
      \   a:dimensions,
      \   hints
      \ )
      return 1
    endif
  endif

  if has_key(candidate.user_data, 'preview_path')
    let path = candidate.user_data.preview_path
    if filereadable(path)
      try
        let lines = readfile(path, '', a:dimensions.height)
        let hints = s:preview_hints_from_candidate(candidate)
        if !has_key(hints, 'filetype')
          let filetype = luis#ui#detect_filetype(path, lines)
          if filetype != ''
            let hints.filetype = filetype
          endif
        endif
        call a:preview_window.open_text(
        \   lines,
        \   a:dimensions,
        \   hints
        \ )
        return 1
      catch /\<E484:/
        call a:preview_window.close()
        return 0
      endtry
    endif
  endif

  call a:preview_window.close()
  return 0
endfunction

function! s:preview_hints_from_candidate(candidate) abort
  let hints = {}

  if has_key(a:candidate.user_data, 'preview_title')
    let hints.title = a:candidate.user_data.preview_title
  endif

  if has_key(a:candidate.user_data, 'preview_cursor')
    let hints.cursor = a:candidate.user_data.preview_cursor
  endif

  if has_key(a:candidate.user_data, 'preview_filetype')
    let hints.filetype = a:candidate.user_data.preview_filetype
  endif

  return hints
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
