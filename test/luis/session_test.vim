silent runtime! test/spy.vim
silent runtime! test/mocks.vim

function! s:test_collect_candidates() abort
  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let [finder, finder_spies] = SpyDict(CreateMockFinder())
  let [source, source_spies] = SpyDict(CreateMockSource({
  \   'candidates': candidates,
  \ }))
  let [matcher, matcher_spies] = SpyDict(CreateMockMatcher())
  let [comparer, comparer_spies] = SpyDict(CreateMockComparer())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#session#new(
  \    finder,
  \    source,
  \    matcher,
  \    comparer,
  \    CreateMockPreviewer(),
  \    hook,
  \ )

  let pattern = 'foo'
  let expected_context = {
  \   'pattern': pattern,
  \   'session': session,
  \ }

  call assert_equal(
  \   candidates,
  \   session.collect_candidates(pattern)
  \ )
  call assert_equal(1, source_spies.gather_candidates.call_count())
  call assert_equal(
  \   [expected_context],
  \   source_spies.gather_candidates.last_args()
  \ )
  call assert_equal(1, matcher_spies.filter_candidates.call_count())
  call assert_equal(
  \   [candidates, expected_context],
  \   matcher_spies.filter_candidates.last_args()
  \ )
  call assert_equal([
  \   [candidates[0], 0, expected_context],
  \   [candidates[1], 1, expected_context],
  \   [candidates[2], 2, expected_context],
  \ ], comparer_spies.normalize_candidate.args())
  call assert_equal([
  \   [candidates[0], 0, expected_context],
  \   [candidates[1], 1, expected_context],
  \   [candidates[2], 2, expected_context],
  \ ], matcher_spies.normalize_candidate.args())
  call assert_equal([
  \   [candidates[0], 0, expected_context],
  \   [candidates[1], 1, expected_context],
  \   [candidates[2], 2, expected_context],
  \ ], hook_spies.normalize_candidate.args())
  call assert_equal([
  \   [candidates[0], 0, expected_context],
  \   [candidates[1], 1, expected_context],
  \   [candidates[2], 2, expected_context],
  \ ], finder_spies.normalize_candidate.args())
  call assert_equal(1, matcher_spies.sort_candidates.call_count())
  call assert_equal(
  \   [candidates, expected_context],
  \   matcher_spies.sort_candidates.last_args()
  \ )
endfunction

function! s:test_preview_candidate__with_buffer_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [previewer, previewer_spies] = SpyDict(CreateMockPreviewer({
  \   'is_active': 0,
  \   'is_available': 1,
  \ }))
  let [hook, hook_spies] = SpyDict(CreateMockHook())

  " With existent buffer
  let candidate = {
  \   'word': 'foo',
  \   'user_data': {
  \     'preview_bufnr': bufnr('%'),
  \     'preview_cursor': [10, 1],
  \   }
  \ }
  let preview_bounds = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }
  let [finder, finder_spies] = SpyDict(CreateMockFinder({
  \   'candidate': candidate,
  \   'preview_bounds': preview_bounds,
  \ }))
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   previewer,
  \   hook
  \ )

  call assert_true(1, session.preview_candidate())
  call assert_equal(1, finder_spies.guess_candidate.call_count())
  call assert_equal(1, source_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session },
  \ ], source_spies.on_preview.last_args())
  call assert_equal(1, hook_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session },
  \ ], hook_spies.on_preview.last_args())
  call assert_equal(1, previewer_spies.open_buffer.call_count())
  call assert_equal(
  \   [
  \     candidate.user_data.preview_bufnr,
  \     preview_bounds,
  \     { 'cursor': candidate.user_data.preview_cursor }
  \   ],
  \   previewer_spies.open_buffer.last_args()
  \ )
  call assert_equal(0, previewer_spies.close.call_count())

  " With non-existent buffer
  let candidate = {
  \   'word': 'foo',
  \   'user_data': {
  \     'preview_bufnr': bufnr('$') + 1,
  \   }
  \ }
  let preview_bounds = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }
  let [finder, finder_spies] = SpyDict(CreateMockFinder({
  \   'candidate': candidate,
  \   'preview_bounds': preview_bounds,
  \ }))
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   previewer,
  \   hook
  \ )

  call assert_true(1, session.preview_candidate())
  call assert_equal(1, finder_spies.guess_candidate.call_count())
  call assert_equal(2, source_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session },
  \ ], source_spies.on_preview.last_args())
  call assert_equal(2, hook_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session },
  \ ], hook_spies.on_preview.last_args())
  call assert_equal(1, previewer_spies.open_buffer.call_count())
  call assert_equal(1, previewer_spies.close.call_count())
endfunction

function! s:test_preview_candidate__with_file_preview() abort
  if !has('nvim') && !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  let [source, source_spies] = SpyDict(CreateMockSource())
  let [previewer, previewer_spies] = SpyDict(CreateMockPreviewer({
  \   'is_active': 0,
  \   'is_available': 1,
  \ }))
  let [hook, hook_spies] = SpyDict(CreateMockHook())

  filetype on

  try
    " With filetype
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'preview_path': 'test/data/seq.txt',
    \     'preview_filetype': 'help',
    \   }
    \ }
    let preview_bounds = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }
    let [finder, finder_spies] = SpyDict(CreateMockFinder({
    \   'candidate': candidate,
    \   'preview_bounds': preview_bounds,
    \ }))
    let session = luis#session#new(
    \   finder,
    \   source,
    \   CreateMockMatcher(),
    \   CreateMockComparer(),
    \   previewer,
    \   hook
    \ )

    call assert_true(session.preview_candidate())
    call assert_equal(1, finder_spies.guess_candidate.call_count())
    call assert_equal(1, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(1, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(1, previewer_spies.open_text.call_count())
    call assert_equal(
    \   [
    \     ['1', '2', '3', '4'],
    \     preview_bounds,
    \     { 'filetype': 'help' },
    \   ],
    \   previewer_spies.open_text.last_args()
    \ )
    call assert_equal(0, previewer_spies.close.call_count())

    " Without filetype (Auto detection)
    let candidate = {
    \   'word': 'hello_world.vim',
    \   'user_data': {
    \     'preview_path': 'test/data/hello_world.vim',
    \   }
    \ }
    let preview_bounds = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }
    let [finder, finder_spies] = SpyDict(CreateMockFinder({
    \   'candidate': candidate,
    \   'preview_bounds': preview_bounds,
    \ }))
    let session = luis#session#new(
    \   finder,
    \   source,
    \   CreateMockMatcher(),
    \   CreateMockComparer(),
    \   previewer,
    \   hook
    \ )

    call assert_true(session.preview_candidate())
    call assert_equal(1, finder_spies.guess_candidate.call_count())
    call assert_equal(2, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(2, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(2, previewer_spies.open_text.call_count())
    call assert_equal(
    \   [
    \     ["echo 'hello, world!'"],
    \     preview_bounds,
    \     { 'filetype': 'vim' },
    \   ],
    \   previewer_spies.open_text.last_args()
    \ )
    call assert_equal(0, previewer_spies.close.call_count())

    " With non-existent file
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'preview_path': tempname(),
    \   }
    \ }
    let preview_bounds = { 'row': 3, 'col': 4, 'width': 5, 'height': 6 }
    let [finder, finder_spies] = SpyDict(CreateMockFinder({
    \   'candidate': candidate,
    \   'preview_bounds': preview_bounds,
    \ }))
    let session = luis#session#new(
    \   finder,
    \   source,
    \   CreateMockMatcher(),
    \   CreateMockComparer(),
    \   previewer,
    \   hook
    \ )

    call assert_false(session.preview_candidate())
    call assert_equal(1, finder_spies.guess_candidate.call_count())
    call assert_equal(3, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(3, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(2, previewer_spies.open_text.call_count())
    call assert_equal(1, previewer_spies.close.call_count())
  finally
    filetype off
  endtry
endfunction

function! s:test_preview_candidate__with_no_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [previewer, previewer_spies] = SpyDict(CreateMockPreviewer({
  \   'is_active': 0,
  \   'is_available': 1,
  \ }))
  let [hook, hook_spies] = SpyDict(CreateMockHook())

  let candidate = { 'word': '', 'user_data': {} }
  let preview_bounds = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }
  let [finder, finder_spies] = SpyDict(CreateMockFinder({
  \   'candidate': candidate,
  \   'preview_bounds': preview_bounds,
  \ }))
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   previewer,
  \   hook
  \ )

  call assert_false(session.preview_candidate())
  call assert_equal(1, finder_spies.guess_candidate.call_count())
  call assert_equal(1, source_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session },
  \ ], source_spies.on_preview.last_args())
  call assert_equal(1, hook_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session },
  \ ], hook_spies.on_preview.last_args())
  call assert_equal(1, previewer_spies.close.call_count())
endfunction

function! s:test_preview_candidate__with_text_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [previewer, previewer_spies] = SpyDict(CreateMockPreviewer({
  \   'is_active': 0,
  \   'is_available': 1,
  \ }))
  let [hook, hook_spies] = SpyDict(CreateMockHook())

  let candidate = {
  \   'word': 'foo',
  \   'user_data': {
  \     'preview_title': 'title',
  \     'preview_lines': ['foo', 'bar', 'baz'],
  \   }
  \ }
  let preview_bounds = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }
  let [finder, finder_spies] = SpyDict(CreateMockFinder({
  \   'candidate': candidate,
  \   'preview_bounds': preview_bounds,
  \ }))
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   previewer,
  \   hook
  \ )

  call assert_true(session.preview_candidate())
  call assert_equal(1, finder_spies.guess_candidate.call_count())
  call assert_equal(1, source_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session },
  \ ], source_spies.on_preview.last_args())
  call assert_equal(1, hook_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session },
  \ ], hook_spies.on_preview.last_args())
  call assert_equal(1, previewer_spies.open_text.call_count())
  call assert_equal(
  \   [
  \     candidate.user_data.preview_lines,
  \     preview_bounds,
  \     { 'title': candidate.user_data.preview_title }
  \   ],
  \   previewer_spies.open_text.last_args()
  \ )
  call assert_equal(0, previewer_spies.close.call_count())
endfunction

function! s:test_quit__with_active_finder() abort
  let [finder, finder_spies] = SpyDict(CreateMockFinder({ 'is_active': 1 }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   hook
  \ )

  call assert_true(session.quit())
  call assert_equal(1, finder_spies.quit.call_count())
  call assert_equal(0, source_spies.on_source_enter.call_count())
  call assert_equal(1, source_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_leave.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_leave.last_self())
  call assert_equal(0, hook_spies.on_source_enter.call_count())
  call assert_equal(1, hook_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_leave.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_leave.last_self())
endfunction

function! s:test_quit__with_inactive_finder() abort
  let [finder, finder_spies] = SpyDict(CreateMockFinder({ 'is_active': 0 }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   hook
  \ )

  redir => OUTPUT
  silent call assert_false(session.quit())
  redir END

  call assert_match('luis: Not active', OUTPUT)
  call assert_equal(0, finder_spies.quit.call_count())
  call assert_equal(0, source_spies.on_source_enter.call_count())
  call assert_equal(0, source_spies.on_source_leave.call_count())
  call assert_equal(0, hook_spies.on_source_enter.call_count())
  call assert_equal(0, hook_spies.on_source_leave.call_count())
endfunction

function! s:test_start__with_active_finder() abort
  let [finder, finder_spies] = SpyDict(CreateMockFinder({ 'is_active': 1 }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   hook
  \ )

  redir => OUTPUT
  silent call assert_false(session.start())
  redir END

  call assert_match('luis: Already active', OUTPUT)
  call assert_equal(0, finder_spies.start.call_count())
  call assert_equal(0, source_spies.on_source_enter.call_count())
  call assert_equal(0, source_spies.on_source_leave.call_count())
  call assert_equal(0, hook_spies.on_source_enter.call_count())
  call assert_equal(0, hook_spies.on_source_leave.call_count())
endfunction

function! s:test_start__with_inactive_finder() abort
  let [finder, finder_spies] = SpyDict(CreateMockFinder({ 'is_active': 0 }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   hook
  \ )

  call assert_true(session.start())
  call assert_equal(1, finder_spies.start.call_count())
  call assert_equal(1, source_spies.on_source_enter.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_enter.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_enter.last_self())
  call assert_equal(0, source_spies.on_source_leave.call_count())
  call assert_equal(1, hook_spies.on_source_enter.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_enter.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_enter.last_self())
  call assert_equal(0, hook_spies.on_source_leave.call_count())
endfunction

function! s:test_take_action__choose_action() abort
  let candidate = { 'word': 'VIM', 'user_data': {} }
  let [finder, finder_spies] = SpyDict(CreateMockFinder({
  \   'candidate': candidate,
  \   'is_active': 1
  \ }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   hook
  \ )

  let action_spy = Spy({ candidate, context -> 0 })
  let kind = session.source.default_kind
  let kind.action_table.default = action_spy.to_funcref()

  call feedkeys("\<CR>", 'nt')
  silent call assert_true(session.take_action(''))
  call assert_equal(0, getchar(0))

  let expected_context = { 'kind': kind, 'session': session }

  call assert_equal(1, finder_spies.quit.call_count())

  call assert_equal(1, source_spies.on_action.call_count())
  call assert_equal([candidate, expected_context], source_spies.on_action.last_args())
  call assert_equal(source, source_spies.on_action.last_self())
  call assert_equal(1, source_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_leave.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_leave.last_self())

  call assert_equal(1, hook_spies.on_action.call_count())
  call assert_equal([candidate, expected_context], hook_spies.on_action.last_args())
  call assert_equal(hook, hook_spies.on_action.last_self())
  call assert_equal(1, hook_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_leave.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_leave.last_self())

  call assert_equal(1, action_spy.call_count())
  call assert_equal([candidate, expected_context], action_spy.last_args())
  call assert_equal(0, action_spy.last_return_value())
endfunction

function! s:test_take_action__do_default_action() abort
  let candidate = { 'word': 'VIM', 'user_data': {} }
  let [finder, finder_spies] = SpyDict(CreateMockFinder({
  \   'candidate': candidate,
  \   'is_active': 1,
  \ }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   hook
  \ )

  let action_spy = Spy({ candidate, context -> 0 })
  let kind = session.source.default_kind
  let kind.action_table.default = action_spy.to_funcref()

  silent call assert_true(session.take_action('default'))

  let expected_context = { 'kind': kind, 'session': session }

  call assert_equal(1, finder_spies.quit.call_count())

  call assert_equal(1, source_spies.on_action.call_count())
  call assert_equal([candidate, expected_context], source_spies.on_action.last_args())
  call assert_equal(source, source_spies.on_action.last_self())
  call assert_equal(1, source_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_leave.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_leave.last_self())

  call assert_equal(1, hook_spies.on_action.call_count())
  call assert_equal([candidate, expected_context], hook_spies.on_action.last_args())
  call assert_equal(hook, hook_spies.on_action.last_self())
  call assert_equal(1, hook_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_leave.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_leave.last_self())

  call assert_equal(1, action_spy.call_count())
  call assert_equal([candidate, expected_context], action_spy.last_args())
  call assert_equal(0, action_spy.last_return_value())
endfunction

function! s:test_take_action__with_candidate_kind() abort
  let action_spy = Spy({ candidate, context -> 0 })
  let kind = CreateMockKind()
  let kind.action_table.default  = action_spy.to_funcref()
  let candidate = { 'word': 'VIM', 'user_data': { 'kind': kind } }
  let [finder, finder_spies] = SpyDict(CreateMockFinder({
  \   'candidate': candidate,
  \   'is_active': 1,
  \ }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#session#new(
  \   finder,
  \   source,
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   hook
  \ )

  silent call assert_true(session.take_action('default'))

  let expected_context = { 'kind': kind, 'session': session }

  call assert_equal(1, finder_spies.quit.call_count())

  call assert_equal(1, source_spies.on_action.call_count())
  call assert_equal([candidate, expected_context], source_spies.on_action.last_args())
  call assert_equal(source, source_spies.on_action.last_self())
  call assert_equal(1, source_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_leave.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_leave.last_self())

  call assert_equal(1, hook_spies.on_action.call_count())
  call assert_equal([candidate, expected_context], hook_spies.on_action.last_args())
  call assert_equal(hook, hook_spies.on_action.last_self())
  call assert_equal(1, hook_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_leave.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_leave.last_self())

  call assert_equal(1, action_spy.call_count())
  call assert_equal([candidate, expected_context], action_spy.last_args())
  call assert_equal(0, action_spy.last_return_value())
endfunction
