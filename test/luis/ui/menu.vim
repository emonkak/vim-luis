function! s:test_guess_candidate__from_completed_item() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let session = luis#ui#menu#new_session(source, {})

  try
    let candidate = { 'word': 'VIM', 'user_data': {} }
    let v:completed_item = candidate
    call assert_equal(candidate, session.guess_candidate())

    " Decode user_data as JSON if it is a string.
    let candidate = { 'word': 'VIM', 'user_data': { 'file_path': '/VIM' } }
    let v:completed_item = { 'word': 'VIM', 'user_data': '{"file_path": "/VIM"}' }
    call assert_equal(candidate, session.guess_candidate())
  catch 'Vim(let):E46:'
    return 'v:completed_item is read-only.'
  endtry

  let v:completed_item = {}
endfunction

function! s:test_guess_candidate__from_first_candidate() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let session = luis#ui#menu#new_session(source, {})

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let luis_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    let session.last_candidates = [
    \   { 'word': 'foo' },
    \   { 'word': 'bar' },
    \   { 'word': 'baz' },
    \ ]
    let session.last_pattern_raw = '>'

    call assert_equal(session.last_candidates[0], session.guess_candidate())

    call session.quit()

    call assert_notequal('luis-menu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_guess_candidate__from_selected_candidate() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let session = luis#ui#menu#new_session(source, {})

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let luis_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    let session.last_candidates = [
    \   { 'word': 'foo' },
    \   { 'word': 'bar' },
    \   { 'word': 'baz' },
    \ ]
    call setline(line('.'), 'bar')

    call assert_equal(session.last_candidates[1], session.guess_candidate())

    call session.quit()

    call assert_notequal('luis-menu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_guess_candidate__from_default_candidate() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let session = luis#ui#menu#new_session(source, {})

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let luis_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    let session.last_candidates = []
    let session.last_pattern_raw = '>VIM'
    call setline(line('.'), '>VIM')

    call assert_equal({ 'word': 'VIM', 'user_data': {} }, session.guess_candidate())

    call session.quit()

    call assert_notequal('luis-menu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_omni_func() abort
  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let kind = s:create_mock_kind()
  let [matcher, matcher_spies] = SpyDict(s:create_mock_matcher())
  let [source, source_spies] = SpyDict(extend(
  \   {
  \     'gather_candidates': { context -> candidates },
  \   },
  \   s:create_mock_source(kind, matcher),
  \   'keep'
  \ ))

  let session = luis#ui#menu#new_session(source, {})

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let luis_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    let pattern = 'foo'
    let expected_context = {
    \   'pattern': pattern,
    \   'matcher': matcher,
    \   'session': session,
    \ }
    let expected_candidates = [
    \   {
    \     'word': 'foo',
    \     'equal': 1,
    \     'user_data': {},
    \     'luis_sort_priority': 0,
    \   },
    \   {
    \     'word': 'foobar',
    \     'equal': 1,
    \     'user_data': {},
    \     'luis_sort_priority': 0,
    \   },
    \   {
    \     'word': 'foobarbaz',
    \     'equal': 1,
    \     'user_data': {},
    \     'luis_sort_priority': 0,
    \   },
    \ ]

    call assert_equal(
    \   expected_candidates,
    \   luis#ui#menu#_omnifunc(0, '>' . pattern)
    \ )
    call assert_equal(
    \   [[expected_context]],
    \   source_spies.gather_candidates.args()
    \ )
    call assert_equal([
    \   [candidates, expected_context],
    \ ], matcher_spies.filter_candidates.args())
    call assert_equal([
    \   [candidates[0], 0, expected_context],
    \   [candidates[1], 1, expected_context],
    \   [candidates[2], 2, expected_context],
    \ ], matcher_spies.normalize_candidate.args())
    call assert_equal([
    \   [expected_candidates, expected_context],
    \ ], matcher_spies.sort_candidates.args())

    call session.quit()

    call assert_notequal('luis-menu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_omni_func__default_matcher() abort
  let kind = s:create_mock_kind()
  let [matcher, matcher_spies] = SpyDict(s:create_mock_matcher())
  let [source, source_spies] = SpyDict(extend(
  \   {
  \     'gather_candidates': { context -> [] },
  \   },
  \   s:create_mock_source(kind, matcher),
  \   'keep'
  \ ))

  let session = luis#ui#menu#new_session(source, {})

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let luis_bufnr = bufnr('%')

  let original_default_matcher = luis#matcher#default#import()
  let g:luis_default_matcher = matcher

  try
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    let pattern = 'foo'
    let expected_context = {
    \   'pattern': pattern,
    \   'matcher': matcher,
    \   'session': session,
    \ }

    call assert_equal(
    \   [],
    \   luis#ui#menu#_omnifunc(0, '>' . pattern)
    \ )
    call assert_equal(
    \   [[expected_context]],
    \   source_spies.gather_candidates.args()
    \ )
    call assert_equal([
    \   [[], expected_context],
    \ ], matcher_spies.filter_candidates.args())
    call assert_false(matcher_spies.normalize_candidate.called())
    call assert_equal([
    \   [[], expected_context],
    \ ], matcher_spies.sort_candidates.args())

    call session.quit()

    call assert_notequal('luis-menu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute luis_bufnr 'bwipeout!'
    let g:luis_default_matcher = original_default_matcher
  endtry
endfunction

function! s:test_reload_candidates() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let source.gather_candidates = { context -> [{ 'word': 'VIM' }] }
  let session = luis#ui#menu#new_session(source, {})

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let luis_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    let callback = {}
    function! callback.call() abort closure
      call session.reload_candidates()
      call assert_equal("\<C-x>", nr2char(getchar(0)))
      call assert_equal("\<C-o>", nr2char(getchar(0)))
      call assert_equal("\<Esc>", nr2char(getchar(0)))
      return ''
    endfunction
    let [callback, callback_spies] = SpyDict(callback)

    silent call feedkeys("i\<C-r>=callback.call()\<CR>", 'nx')
    call assert_equal(1, callback_spies.call.call_count())

    call session.quit()

    call assert_notequal('luis-menu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_start() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let session = luis#ui#menu#new_session(source)

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let luis_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(0, source_spies.on_source_leave.call_count())

    call session.quit()

    call assert_notequal('luis-menu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(1, source_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_leave.last_args()
    \ )

    call session.start()

    " Reuse existing luis buffer.
    call assert_equal('A', s:consume_keys())
    call assert_equal(luis_bufnr, bufnr('%'))
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())
    call assert_equal(2, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(1, source_spies.on_source_leave.call_count())

    call session.quit()

    call assert_notequal('luis-menu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
    call assert_equal(2, source_spies.on_source_enter.call_count())
    call assert_equal(2, source_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_leave.last_args()
    \ )
  finally
    execute luis_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_start__with_options() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let [hook, hook_spies] = SpyDict({
  \   'on_source_enter': { context -> 0 },
  \   'on_source_leave': { context -> 0 },
  \ })
  let session = luis#ui#menu#new_session(source, {
  \   'hook': hook,
  \   'initial_pattern': 'VIM',
  \ })

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let luis_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, luis_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())

    call session.quit()

    call assert_notequal('luis-menu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(1, source_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_leave.last_args()
    \ )
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(1, hook_spies.on_source_leave.call_count())

    call session.start()

    " Reuse existing luis buffer.
    call assert_equal(luis_bufnr, bufnr('%'))
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-menu', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())
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

function! s:create_mock_kind() abort
  return {
  \   'name': 'mock_kind',
  \   'action_table': {
  \     'default': { candidate, context -> 0 },
  \   },
  \   'key_table': {
  \     "\<CR>": 'default',
  \   },
  \ }
endfunction

function! s:create_mock_matcher() abort
  return {
  \   'filter_candidates': { candidates, context -> candidates },
  \   'normalize_candidate': { candidate, index, context -> candidate },
  \   'sort_candidates': { candidates, context -> candidates },
  \ }
endfunction

function! s:create_mock_source(default_kind, matcher) abort
  return {
  \   'default_kind': a:default_kind,
  \   'gather_candidates': { context -> [] },
  \   'is_valid_for_acc': { candidate -> 1 },
  \   'matcher': a:matcher,
  \   'name': 'mock_source',
  \   'on_action': { candidate, context -> 0 },
  \   'on_source_enter': { context -> 0 },
  \   'on_source_leave': { context -> 0 },
  \ }
endfunction
