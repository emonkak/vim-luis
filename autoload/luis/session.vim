function! luis#session#new(finder, source, matcher, comparer, previewer, hook) abort
  let session = copy(s:Session)
  let session.finder = a:finder
  let session.source = a:source
  let session.matcher = a:matcher
  let session.comparer = a:comparer
  let session.previewer = a:previewer
  let session.hook = a:hook
  return session
endfunction

let s:Session = {}

function! s:Session.collect_candidates(pattern) abort dict
  let context = { 'pattern': a:pattern, 'session': self }
  let normalizers = []

  if has_key(self.comparer, 'normalize_candidate')
    call add(normalizers, self.comparer)
  endif
  if has_key(self.matcher, 'normalize_candidate')
    call add(normalizers, self.matcher)
  endif
  if has_key(self.hook, 'normalize_candidate')
    call add(normalizers, self.hook)
  endif
  if has_key(self.finder, 'normalize_candidate')
    call add(normalizers, self.finder)
  endif

  let candidates = self.source.gather_candidates(context)
  let candidates = self.matcher.filter_candidates(candidates, context)
  for i in range(len(candidates))
    " Action expects 'user_data' to be defined, so we will complete it.
    if !has_key(candidates[i], 'user_data')
      let candidates[i].user_data = {}
    endif
    for normalizer in normalizers
      let candidates[i] = normalizer.normalize_candidate(
      \   candidates[i],
      \   i,
      \   context
      \ )
    endfor
  endfor
  let candidates = self.matcher.sort_candidates(candidates, context)

  return candidates
endfunction

function! s:Session.preview_candidate() abort
  let previewer = self.previewer
  if !previewer.is_available()
    return 0
  endif

  let candidate = self.finder.guess_candidate()
  let context = { 'session': self }

  if has_key(self.source, 'on_preview')
    call self.source.on_preview(candidate, context)
  endif

  if has_key(self.hook, 'on_preview')
    call self.hook.on_preview(candidate, context)
  endif

  if has_key(candidate.user_data, 'preview_lines')
    let hints = s:preview_hints_from_candidate(candidate)
    let bounds = self.finder.preview_bounds()
    call previewer.open_text(
    \   candidate.user_data.preview_lines,
    \   bounds,
    \   hints
    \ )
    return 1
  endif

  if has_key(candidate.user_data, 'preview_bufnr')
    let bufnr = candidate.user_data.preview_bufnr
    if bufloaded(bufnr)
      let bounds = self.finder.preview_bounds()
      let hints = s:preview_hints_from_candidate(candidate)
      call previewer.open_buffer(
      \   bufnr,
      \   bounds,
      \   hints
      \ )
      return 1
    endif
  endif

  if has_key(candidate.user_data, 'preview_path')
    let path = candidate.user_data.preview_path
    if filereadable(path)
      try
        let bounds = self.finder.preview_bounds()
        let lines = readfile(path, '', bounds.height)
        let hints = s:preview_hints_from_candidate(candidate)
        if !has_key(hints, 'filetype')
          let filetype = luis#detect_filetype(path, lines)
          if filetype != ''
            let hints.filetype = filetype
          endif
        endif
        call previewer.open_text(
        \   lines,
        \   bounds,
        \   hints
        \ )
        return 1
      catch /\<E484:/
        call previewer.close()
        return 0
      endtry
    endif
  endif

  call previewer.close()
  return 0
endfunction

function! s:Session.quit() abort
  if !self.finder.is_active()
    echohl ErrorMsg
    echo 'luis: Not active'
    echohl NONE
    return 0
  endif

  let context = { 'session': self }

  if has_key(self.source, 'on_source_leave')
    call self.source.on_source_leave(context)
  endif

  if has_key(self.hook, 'on_source_leave')
    call self.hook.on_source_leave(context)
  endif

  if self.previewer.is_available()
    call self.previewer.close()
  endif

  call self.finder.quit()

  return 1
endfunction

function! s:Session.start() abort dict
  if self.finder.is_active()
    echohl ErrorMsg
    echo 'luis: Already active'
    echohl NONE
    return 0
  endif

  call self.finder.start(self)

  let context = { 'session': self }

  if has_key(self.hook, 'on_source_enter')
    call self.hook.on_source_enter(context)
  endif

  if has_key(self.source, 'on_source_enter')
    call self.source.on_source_enter(context)
  endif

  return 1
endfunction

function! s:Session.take_action(action_name) abort
  let candidate = self.finder.guess_candidate()
  let kind = s:kind_from_candidate(candidate, self.source.default_kind)
  let action_name = a:action_name != ''
  \               ? a:action_name
  \               : s:choose_action(kind, candidate)

  " Close the luis window, because some kind of actions does something on the
  " current buffer/window and user expects that such actions do something on
  " the buffer/window which was the current one until the luis buffer became
  " active.
  call self.quit()

  if action_name == ''
    " In these cases, error messages are already noticed by other functions.
    return 0
  endif

  let context = { 'kind': kind, 'session': self }

  if has_key(self.source, 'on_action')
    call self.source.on_action(candidate, context)
  endif

  if has_key(self.hook, 'on_action')
    call self.hook.on_action(candidate, context)
  endif

  let result = luis#do_action(action_name, candidate, context)
  if result isnot 0
    echohl ErrorMsg
    echomsg result
    echohl NONE
  endif

  return 1
endfunction

function! s:choose_action(kind, candidate) abort
  " Prompt      Candidate Source
  "    |          |         |
  "   _^_______  _^______  _^__
  "   Candidate: Makefile (file)
  "   ^C cancel      ^O open        ...
  "   What action?   ~~ ~~~~
  "   ~~~~~~~~~~~~    |   |
  "         |         |   |
  "      Message     Key  Action
  "
  " Here "Prompt" is highlighted with luisChoosePrompt,
  " "Candidate" is highlighted with luisChooseCandidate, and so forth.
  let key_table = s:composite_key_table(a:kind)
  " "Candidate: {candidate} ({source})"
  echohl NONE
  echo ''
  echohl luisChoosePrompt
  echon 'Candidate'
  echohl NONE
  echon ': '
  echohl luisChooseCandidate
  echon a:candidate.word
  echohl NONE
  echon ' ('
  echohl luisChooseKind
  echon a:kind.name
  echohl NONE
  echon ')'
  call s:list_key_bindings(key_table)
  echohl luisChooseMessage
  echo 'What action? '
  echohl NONE

  " Take user input.
  let k = s:get_key()
  redraw  " clear the menu message lines to avoid hit-enter prompt.

  " Return the action bound to the key k.
  if has_key(key_table, k)
    return key_table[k]
  else
    echo 'The key' string(k) 'is not associated with any action'
    \    '-- nothing happened.'
    return 0
  endif
endfunction

function! s:compare_ignorecase(x, y) abort
  " Comparing function for sort() to do consistently case-insensitive sort.
  "
  " sort(list, 1) does case-insensitive sort,
  " but its result may not be in a consistent order.
  " For example,
  " sort(['b', 'a', 'B', 'A'], 1) may return ['a', 'A', 'b', 'B'],
  " sort(['b', 'A', 'B', 'a'], 1) may return ['A', 'a', 'b', 'B'],
  " and so forth.
  "
  " With this function, sort() always return ['A', 'a', 'B', 'b'].
  return a:x <? a:y ? -1
  \    : a:x >? a:y ? 1
  \    : a:x <# a:y ? -1
  \    : a:x ># a:y ? 1
  \    : 0
endfunction

function! s:composite_key_table(kind) abort
  let key_table = {}
  let kind = a:kind

  while 1
    call extend(key_table, kind.key_table)
    if !has_key(kind, 'prototype')
      break
    endif
    let kind = kind.prototype
  endwhile

  return key_table
endfunction

function! s:find_action(kind, action_name) abort
  let kind = a:kind

  while 1
    if has_key(kind.action_table, a:action_name)
      return kind.action_table[a:action_name]
    endif
    if !has_key(kind, 'prototype')
      break
    endif
    let kind = kind.prototype
  endwhile

  return 0
endfunction

function! s:get_key() abort
  " Alternative getchar() to get a logical key such as <F1> and <M-{x}>.
  let k1 = getchar()
  let k1 = type(k1) is v:t_number ? nr2char(k1) : k1

  if k1 ==# "\<Esc>"
    let k2 = getchar(0)
    let k2 = type(k2) is v:t_number ? nr2char(k2) : k2
    return k1 . k2
  else
    return k1
  endif
endfunction

function! s:kind_from_candidate(candidate, default_kind) abort
  return has_key(a:candidate.user_data, 'kind')
  \      ? a:candidate.user_data.kind
  \      : a:default_kind
endfunction

function! s:list_key_bindings(key_table) abort
  " actions => {
  "   'keys': [[key_value, key_repr], ...],
  "   'label': label
  " }
  let actions = {}
  for [key, action_name] in items(a:key_table)
    if !has_key(actions, action_name)
      let actions[action_name] = { 'keys': [] }
    endif
    call add(actions[action_name].keys, [key, strtrans(key)])
  endfor
  for action in values(actions)
    call sort(action.keys)
    let action.label = join(map(copy(action.keys), 'v:val[1]'), ' ')
  endfor

  " key  action
  " ---  ------
  "  ^H  left
  " -----------
  "   cell
  let action_names = sort(keys(actions), 's:compare_ignorecase')
  let max_action_name_width = max(map(keys(actions), 'len(v:val)'))
  let max_label_width = max(map(values(actions), 'len(v:val.label)'))
  let max_cell_width = max_action_name_width + 1 + max_label_width
  let spacer = '   '
  let columns = (&columns + len(spacer) - 1) / (max_cell_width + len(spacer))
  let columns = max([columns, 1])
  let n = len(actions)
  let rows = n / columns + (n % columns != 0)

  for row in range(rows)
    for column in range(columns)
      let i = column * rows + row
      if !(i < n)
        continue
      endif

      echon column == 0 ? "\n" : spacer

      echohl luisChooseAction
      let _ = action_names[i]
      echon _
      echohl NONE
      echon repeat(' ', max_action_name_width - len(_))

      echohl luisChooseKey
      echon ' '
      let _ = actions[action_names[i]].label
      echon _
      echohl NONE
      echon repeat(' ', max_label_width - len(_))
    endfor
  endfor
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
