function! s:action_default(kind, candidate) abort
  silent new `=a:candidate.word`
  return 0
endfunction

let s:Kind = {
\   'name': 'test',
\   'action_table': { 'default': function('s:action_default') },
\   'key_table': {
\     "\<CR>": 'default',
\   },
\ }

let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, context) abort dict 
  return filter(
  \   copy(a:candidates),
  \   'stridx(v:val.word, a:context.pattern) >= 0'
  \ )
endfunction

function! s:Matcher.normalize_candidate(candidate, index, context) abort dict 
  let a:candidate.user_data = { 'normalized':  1 }
  return a:candidate
endfunction

function! s:Matcher.sort_candidates(candidates, context) abort dict
  return sort(a:candidates, { x, y ->
  \   x.word < y.word ? -1 : x.word > y.word ? 1 : 0
  \ })
endfunction

let s:Source = {
\   'name': 'test',
\   'default_kind': s:Kind,
\   'matcher': s:Matcher,
\ }

function! s:Source.gather_candidates(context) abort dict
  return map(range(10, 0, -1), '{ "word": printf("%02d", v:val) }')
endfunction

function! s:test_choose_action() abort
  let original_bufnr = bufnr('%')
  call assert_equal(1, luis#start(s:Source))

  try
    let luis_bufnr = bufnr('%')
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal(1, winnr())
    call assert_equal(2, winnr('$'))
    call assert_equal('A', s:consume_keys())

    let pattern = 'VIM'
    let candidate = {
    \   'word': tempname(),
    \   'equal': 1,
    \   'user_data': {},
    \   'luis_sort_priority': 0,
    \ }
    let session = luis#_session()
    let session.last_pattern_raw = '>' . pattern
    let session.last_candidates = [candidate]
    call setline(line('.'), '>' . pattern)

    silent execute 'normal' "\<Plug>(luis-choose-action)\<CR>"
    call assert_equal(candidate.word, bufname(''))
    bwipeout

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr())
    call assert_equal(1, winnr('$'))
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_omni_func() abort
  let original_bufnr = bufnr('%')
  call assert_equal(1, luis#start(s:Source))

  try
    let luis_bufnr = bufnr('%')
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal(1, winnr())
    call assert_equal(2, winnr('$'))
    call assert_equal('A', s:consume_keys())

    let pattern = '1'
    call setline(line('.'), pattern)

    call assert_equal([
    \   {
    \     'word': '01',
    \     'equal': 1,
    \     'user_data': { 'normalized':  1 },
    \     'luis_sort_priority': 0,
    \   },
    \   {
    \     'word': '10',
    \     'equal': 1,
    \     'user_data': { 'normalized':  1 },
    \     'luis_sort_priority': 0,
    \   },
    \ ], luis#_omnifunc(0, pattern))

    execute 'normal' "\<Plug>(luis-quit-session)"

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr())
    call assert_equal(1, winnr('$'))
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_restart() abort
  let original_bufnr = bufnr('%')
  call assert_equal(1, luis#start(s:Source, { 'initial_pattern': 'VIM' }))

  try
    let luis_bufnr = bufnr('%')
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('luis', &l:filetype)
    call assert_notequal(original_bufnr, bufnr(''))
    call assert_equal(['Source: test', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_equal('A', s:consume_keys())

    let session = luis#_session()
    let session.last_pattern_raw = '>VIM'

    execute 'normal' "\<Plug>(luis-quit-session)"

    call assert_notequal('luis', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())

    let _ = luis#restart()
    call assert_equal(1, _)

    call assert_equal('A', s:consume_keys())
    call assert_equal('luis', &l:filetype)
    call assert_notequal(original_bufnr, bufnr(''))
    call assert_equal(['Source: test', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_start() abort
  let original_bufnr = bufnr('%')
  call assert_equal(1, luis#start(s:Source))

  try
    let luis_bufnr = bufnr('%')
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('luis', &l:filetype)
    call assert_equal(['Source: test', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_equal('A', s:consume_keys())

    execute 'normal' "\<Plug>(luis-quit-session)"

    call assert_notequal('luis', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())

    " Reuse existing luis buffer.
    call assert_equal(1, luis#start(s:Source))
    call assert_equal('A', s:consume_keys())
    call assert_equal(luis_bufnr, bufnr('%'))

    " Fail while the ku buffer is active.
    silent call assert_equal(0, luis#start(s:Source))
    call assert_equal('', s:consume_keys())
    call assert_equal(luis_bufnr, bufnr('%'))

    execute 'normal' "\<Plug>(luis-quit-session)"

    " Fail if {source} is invalid
    silent! call assert_equal(0, luis#start({}))
    call assert_equal('', s:consume_keys())
    call assert_equal(original_bufnr, bufnr('%'))
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_start__with_hook() abort
  let on_source_enter = Spy({ -> 0 })
  let on_source_leave = Spy({ -> 0 })
  let hook = {
  \   'on_source_enter': on_source_enter.to_funcref(),
  \   'on_source_leave': on_source_leave.to_funcref(),
  \ }

  let original_bufnr = bufnr('%')
  call assert_equal(1, luis#start(s:Source, { 'hook': hook }))

  try
    let luis_bufnr = bufnr('%')
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('luis', &l:filetype)
    call assert_equal(['Source: test', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_equal('A', s:consume_keys())

    call assert_equal(1, on_source_enter.call_count())
    call assert_equal(0, on_source_leave.call_count())

    execute 'normal' "\<Plug>(luis-quit-session)"

    call assert_notequal('luis', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())

    call assert_equal(1, on_source_enter.call_count())
    call assert_equal(1, on_source_leave.call_count())
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_take_action() abort
  let original_bufnr = bufnr('%')
  call assert_equal(1, luis#start(s:Source))

  try
    let luis_bufnr = bufnr('%')
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal(1, winnr())
    call assert_equal(2, winnr('$'))
    call assert_equal('A', s:consume_keys())

    let pattern = 'VIM'
    let candidate = {
    \   'word': pattern,
    \   'equal': 1,
    \   'user_data': {},
    \   'luis_sort_priority': 0,
    \ }

    let session = luis#_session()
    let session.last_pattern_raw = '>' . pattern
    let session.last_candidates = [candidate]
    call setline(line('.'), pattern)

    call assert_equal(1, luis#take_action('default'))
    call assert_equal(candidate.word, bufname(''))
    bwipeout!

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr())
    call assert_equal(1, winnr('$'))
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_take_action__action_is_not_defined() abort
  let original_bufnr = bufnr('%')
  call assert_equal(1, luis#start(s:Source))

  try
    let luis_bufnr = bufnr('%')
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal(1, winnr())
    call assert_equal(2, winnr('$'))
    call assert_equal('A', s:consume_keys())

    let pattern = 'VIM'
    let candidate = {
    \   'word': pattern,
    \   'equal': 1,
    \   'user_data': {},
    \   'luis_sort_priority': 0,
    \ }

    let session = luis#_session()
    let session.last_pattern_raw = '>' . pattern
    let session.last_candidates = [candidate]
    call setline(line('.'), pattern)

    silent call assert_equal(0, luis#take_action(''))

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr())
    call assert_equal(1, winnr('$'))
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_take_action__with_kind() abort
  let original_bufnr = bufnr('%')
  call assert_equal(1, luis#start(s:Source))

  try
    let luis_bufnr = bufnr('%')
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal(1, winnr())
    call assert_equal(2, winnr('$'))
    call assert_equal('A', s:consume_keys())

    let action_table = {}

    function! action_table.default(kind, candidate) abort
      call setline(1, a:candidate.word)
      return 0
    endfunction

    let pattern = 'VIM'
    let kind = {
    \   'name': 'test',
    \   'action_table': action_table,
    \   'key_table': {
    \     "\<CR>": 'default',
    \   },
    \ }
    let candidate = {
    \   'word': tempname(),
    \   'equal': 1,
    \   'user_data': { 'kind': kind },
    \   'luis_sort_priority': 0,
    \ }

    let session = luis#_session()
    let session.last_pattern_raw = '>' . pattern
    let session.last_candidates = [candidate]
    call setline(line('.'), '>' . pattern)

    silent call assert_equal(1, luis#take_action('default'))

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr())
    call assert_equal(1, winnr('$'))
    call assert_equal([candidate.word], getline(1, line('$')))

    bwipeout!
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_take_action__no_candidate() abort
  let original_bufnr = bufnr('%')
  call assert_equal(1, luis#start(s:Source))

  try
    let luis_bufnr = bufnr('%')
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal(1, winnr())
    call assert_equal(2, winnr('$'))
    call assert_equal('A', s:consume_keys())

    let pattern = tempname()

    let session = luis#_session()
    let session.last_pattern_raw = '>' . pattern
    let session.last_candidates = []
    call setline(line('.'), '>' . pattern)

    call assert_equal(1, luis#take_action('default'))
    call assert_equal(pattern, bufname(''))
    bwipeout!

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr())
    call assert_equal(1, winnr('$'))
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:consume_keys() abort
  let keys = ''
  while 1
    let char = getchar(0)
    if char is 0
      break
    endif
    let keys .= nr2char(char)
  endwhile
  return keys
endfunction
