silent runtime! test/spy.vim
silent runtime! test/mocks.vim

function! s:test_acc_text() abort
  let source = CreateMockSource({
  \   'is_valid_for_acc': { candidate ->
  \     get(candidate, 'is_valid_for_acc', 1)
  \   },
  \ })

  let cs1 = [
  \   { 'word': 'usr/share/man/man1' },
  \ ]
  let cs2 = [
  \   { 'word': 'usr/share/w y 1' },
  \   { 'word': 'usr/share/ x z2' },
  \   { 'word': 'usr/share/w y 3' },
  \   { 'word': 'usr/share/ x z4' },
  \ ]
  let cs3 = [
  \   { 'word': 'bin/1/1' },
  \   { 'word': 'etc/2/2' },
  \   { 'word': 'usr/3/3' },
  \   { 'word': 'var/4/4' },
  \ ]
  let cs4 = [
  \   { 'word': '1/X', 'is_valid_for_acc': 0 },
  \   { 'word': '2/X', 'is_valid_for_acc': 0 },
  \   { 'word': '3/X' },
  \   { 'word': '4/X', 'is_valid_for_acc': 0 },
  \ ]

  " len(components) == 2
  call assert_equal('usr', luis#acc_text('/', cs1, source))
  call assert_equal('usr', luis#acc_text('u/', cs1, source))
  call assert_equal('usr', luis#acc_text('s/', cs1, source))
  call assert_equal('usr/share', luis#acc_text('sh/', cs1, source))
  call assert_equal('usr/share/man', luis#acc_text('m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#acc_text('1/', cs1, source))

  call assert_equal('usr/share/w y 1', luis#acc_text('w/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#acc_text('x/', cs2, source))
  call assert_equal('usr/share/w y 1', luis#acc_text('y/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#acc_text('z/', cs2, source))

  call assert_equal('bin', luis#acc_text('b/', cs3, source))
  call assert_equal('etc', luis#acc_text('e/', cs3, source))
  call assert_equal('usr', luis#acc_text('r/', cs3, source))
  call assert_equal('usr', luis#acc_text('u/', cs3, source))
  call assert_equal('var', luis#acc_text('v/', cs3, source))

  call assert_equal('3/X', luis#acc_text('X/', cs4, source))

  " len(components) >= 3
  call assert_equal('usr/share', luis#acc_text('usr//', cs1, source))
  call assert_equal('usr/share', luis#acc_text('usr/s/', cs1, source))
  call assert_equal('usr/share', luis#acc_text('usr/sh/', cs1, source))
  call assert_equal('usr/share/man', luis#acc_text('usr/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#acc_text('usr/1/', cs1, source))
  call assert_equal('usr/share', luis#acc_text('usr/share/', cs1, source))

  call assert_equal('usr/share/man', luis#acc_text('usr/share//', cs1, source))
  call assert_equal('usr/share/man', luis#acc_text('usr/share/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#acc_text('usr/share/1/', cs1, source))

  call assert_equal('etc/2', luis#acc_text('etc//', cs3, source))
  call assert_equal('var/4', luis#acc_text('var//', cs3, source))

  " No components
  let v:errmsg = ''
  silent! call luis#acc_text('', [], source)
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  let v:errmsg = ''
  silent! call assert_equal('', luis#acc_text('', cs1, source))
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  " No proper candidate for a:pattern
  call assert_equal('', luis#acc_text('x/', [], source))
  call assert_equal('', luis#acc_text('x/', cs1, source))
  call assert_equal('', luis#acc_text('2/', cs1, source))
  call assert_equal('', luis#acc_text('u/s/m/', cs1, source))
  call assert_equal('', luis#acc_text('USR//', cs1, source))
endfunction

function! s:test_collect_candidates() abort
  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let [ui, ui_spies] = SpyDict(CreateMockUI())
  let [source, source_spies] = SpyDict(CreateMockSource({
  \   'candidates': candidates,
  \ }))
  let [matcher, matcher_spies] = SpyDict(CreateMockMatcher())
  let [comparer, comparer_spies] = SpyDict(CreateMockComparer())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': matcher,
  \   'comparer': comparer,
  \   'previewer': CreateMockPreviewer(),
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  let pattern = 'foo'
  let expected_context = {
  \   'pattern': pattern,
  \   'session': session,
  \ }

  call assert_equal(
  \   candidates,
  \   luis#collect_candidates(session, pattern)
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
  \ ], ui_spies.normalize_candidate.args())
  call assert_equal(1, matcher_spies.sort_candidates.call_count())
  call assert_equal(
  \   [candidates, expected_context],
  \   matcher_spies.sort_candidates.last_args()
  \ )
endfunction

function! s:test_preview_candidate__with_buffer_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [previewer, previewer_spies] = SpyDict(CreateMockPreviewer({
  \   'is_active': 1,
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
  let [ui, ui_spies] = SpyDict(CreateMockUI({
  \   'candidate': candidate,
  \   'preview_bounds': preview_bounds,
  \ }))
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': previewer,
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  call assert_true(luis#preview_candidate(session))
  call assert_equal(1, ui_spies.guess_candidate.call_count())
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
  \     {
  \       'bufnr': candidate.user_data.preview_bufnr,
  \       'cursor': candidate.user_data.preview_cursor,
  \     },
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
  let [ui, ui_spies] = SpyDict(CreateMockUI({
  \   'candidate': candidate,
  \   'preview_bounds': preview_bounds,
  \ }))
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': previewer,
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  call assert_false(luis#preview_candidate(session))
  call assert_equal(1, ui_spies.guess_candidate.call_count())
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
  \   'is_active': 1,
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
    let [ui, ui_spies] = SpyDict(CreateMockUI({
    \   'candidate': candidate,
    \   'preview_bounds': preview_bounds,
    \ }))
    let session = luis#new_session(source, {
    \   'ui': ui,
    \   'matcher': CreateMockMatcher(),
    \   'comparer': CreateMockComparer(),
    \   'previewer': previewer,
    \   'hook': hook,
    \   'initial_pattern': '',
    \ })

    call assert_true(luis#preview_candidate(session))
    call assert_equal(1, ui_spies.guess_candidate.call_count())
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
    \     ['1', '2', '3', '4', '5'],
    \     preview_bounds,
    \     { 'path': 'test/data/seq.txt', 'filetype': 'help' },
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
    let [ui, ui_spies] = SpyDict(CreateMockUI({
    \   'candidate': candidate,
    \   'preview_bounds': preview_bounds,
    \ }))
    let session = luis#new_session(source, {
    \   'ui': ui,
    \   'matcher': CreateMockMatcher(),
    \   'comparer': CreateMockComparer(),
    \   'previewer': previewer,
    \   'hook': hook,
    \   'initial_pattern': '',
    \ })

    call assert_false(luis#preview_candidate(session))
    call assert_equal(1, ui_spies.guess_candidate.call_count())
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
    call assert_equal(1, previewer_spies.open_text.call_count())
    call assert_equal(1, previewer_spies.close.call_count())
  finally
    filetype off
  endtry
endfunction

function! s:test_preview_candidate__with_no_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [previewer, previewer_spies] = SpyDict(CreateMockPreviewer({
  \   'is_active': 1,
  \ }))
  let [hook, hook_spies] = SpyDict(CreateMockHook())

  let candidate = { 'word': '', 'user_data': {} }
  let preview_bounds = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }
  let [ui, ui_spies] = SpyDict(CreateMockUI({
  \   'candidate': candidate,
  \   'preview_bounds': preview_bounds,
  \ }))
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': previewer,
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  call assert_false(luis#preview_candidate(session))
  call assert_equal(1, ui_spies.guess_candidate.call_count())
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
  \   'is_active': 1,
  \ }))
  let [hook, hook_spies] = SpyDict(CreateMockHook())

  let candidate = {
  \   'word': 'foo',
  \   'user_data': {
  \     'preview_path': 'foo/bar/baz',
  \     'preview_lines': ['foo', 'bar', 'baz'],
  \   }
  \ }
  let preview_bounds = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }
  let [ui, ui_spies] = SpyDict(CreateMockUI({
  \   'candidate': candidate,
  \   'preview_bounds': preview_bounds,
  \ }))
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': previewer,
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  call assert_true(luis#preview_candidate(session))
  call assert_equal(1, ui_spies.guess_candidate.call_count())
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
  \     { 'path': 'foo/bar/baz' }
  \   ],
  \   previewer_spies.open_text.last_args()
  \ )
  call assert_equal(0, previewer_spies.close.call_count())
endfunction

function! s:test_quit__with_active_ui() abort
  let [ui, ui_spies] = SpyDict(CreateMockUI({ 'is_active': 1 }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  call assert_true(luis#quit(session))
  call assert_equal(1, ui_spies.quit.call_count())
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

function! s:test_quit__with_inactive_ui() abort
  let [ui, ui_spies] = SpyDict(CreateMockUI({ 'is_active': 0 }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  redir => OUTPUT
  silent call assert_false(luis#quit(session))
  redir END

  call assert_match('luis: Not active', OUTPUT)
  call assert_equal(0, ui_spies.quit.call_count())
  call assert_equal(0, source_spies.on_source_enter.call_count())
  call assert_equal(0, source_spies.on_source_leave.call_count())
  call assert_equal(0, hook_spies.on_source_enter.call_count())
  call assert_equal(0, hook_spies.on_source_leave.call_count())
endfunction

function! s:test_start__with_active_ui() abort
  let [ui, ui_spies] = SpyDict(CreateMockUI({ 'is_active': 1 }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let matcher = CreateMockMatcher()
  let comparer = CreateMockComparer()
  let previewer = CreateMockPreviewer()
  let [hook, hook_spies] = SpyDict(CreateMockHook())

  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': matcher,
  \   'comparer': comparer,
  \   'previewer': previewer,
  \   'hook': hook,
  \ })
  call assert_equal({
  \   'id': session.id,
  \   'source': source,
  \   'ui': ui,
  \   'matcher': matcher,
  \   'comparer': comparer,
  \   'previewer': previewer,
  \   'hook': hook,
  \   'initial_pattern': '',
  \ }, session)

  redir => OUTPUT
  silent call assert_false(luis#start(session))
  redir END

  call assert_match('luis: Already active', OUTPUT)
  call assert_equal(0, ui_spies.start.call_count())
  call assert_equal(0, source_spies.on_source_enter.call_count())
  call assert_equal(0, source_spies.on_source_leave.call_count())
  call assert_equal(0, hook_spies.on_source_enter.call_count())
  call assert_equal(0, hook_spies.on_source_leave.call_count())
endfunction

function! s:test_start__with_inactive_ui() abort
  let [ui, ui_spies] = SpyDict(CreateMockUI({ 'is_active': 0 }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let matcher = CreateMockMatcher()
  let comparer = CreateMockComparer()
  let previewer = CreateMockPreviewer()
  let [hook, hook_spies] = SpyDict(CreateMockHook())

  " With parameters
  let session_1 = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': matcher,
  \   'comparer': comparer,
  \   'previewer': previewer,
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  call assert_equal({
  \   'id': session_1.id,
  \   'source': source,
  \   'ui': ui,
  \   'matcher': matcher,
  \   'comparer': comparer,
  \   'previewer': previewer,
  \   'hook': hook,
  \   'initial_pattern': '',
  \ }, session_1)
  call assert_true(luis#start(session_1))
  call assert_equal(1, ui_spies.start.call_count())
  call assert_equal(1, source_spies.on_source_enter.call_count())
  call assert_equal(
  \   [{ 'session': session_1 }],
  \   source_spies.on_source_enter.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_enter.last_self())
  call assert_equal(0, source_spies.on_source_leave.call_count())
  call assert_equal(1, hook_spies.on_source_enter.call_count())
  call assert_equal(
  \   [{ 'session': session_1 }],
  \   hook_spies.on_source_enter.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_enter.last_self())
  call assert_equal(0, hook_spies.on_source_leave.call_count())

  " Without any parameters
  let original_defualt_ui = g:luis#default_ui
  let g:luis#default_ui = ui
  try
    let session_2 = luis#new_session(source)

    call assert_equal({
    \   'id': session_2.id,
    \   'source': source,
    \   'ui': g:luis#default_ui,
    \   'matcher': g:luis#default_matcher,
    \   'comparer': g:luis#default_comparer,
    \   'previewer': g:luis#default_previewer,
    \   'hook': {},
    \   'initial_pattern': '',
    \ }, session_2)
    call assert_true(luis#start(session_2))
    call assert_notequal(session_1.id, session_2.id)
    call assert_equal(2, ui_spies.start.call_count())
    call assert_equal(2, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session_2 }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
  finally
    let g:luis#default_ui = original_defualt_ui
  endtry
endfunction

function! s:test_take_action__with_choose_action() abort
  if !has('nvim') && !has('ttyin')
    return 'TTY is required.'
  endif

  let action_spy = Spy({ candidate, context -> 0 })
  let candidate = { 'word': 'VIM', 'user_data': {} }

  let [ui, ui_spies] = SpyDict(CreateMockUI({
  \   'is_active': 1,
  \   'candidate': candidate,
  \ }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  let kind = session.source.default_kind
  let kind.action_table.default = action_spy.to_funcref()

  call feedkeys("\<CR>", 'nt')
  silent call assert_true(luis#take_action(session, '*'))
  call assert_equal(0, getchar(0))

  let expected_context = {
  \   'action': kind.action_table.default,
  \   'action_name': 'default',
  \   'kind': kind,
  \   'session': session,
  \ }

  call assert_equal(1, ui_spies.quit.call_count())
  call assert_equal(1, ui_spies.guess_candidate.call_count())

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

function! s:test_take_action__with_kind() abort
  if !has('nvim') && !has('ttyin')
    return 'TTY is required.'
  endif

  let action_spy = Spy({ candidate, context -> 0 })
  let kind = CreateMockKind()
  let kind.action_table.default = action_spy.to_funcref()
  let candidate = { 'word': 'VIM', 'user_data': { 'kind': kind } }

  let [ui, ui_spies] = SpyDict(CreateMockUI({
  \   'candidate': candidate,
  \   'is_active': 1,
  \ }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  call assert_true(1, luis#take_action(session, 'default'))

  let expected_context = {
  \   'action': kind.action_table.default,
  \   'action_name': 'default',
  \   'kind': kind,
  \   'session': session,
  \ }

  call assert_equal(1, ui_spies.quit.call_count())
  call assert_equal(1, ui_spies.guess_candidate.call_count())

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

function! s:test_take_action__with_ad_hoc_candidate() abort
  if !has('nvim') && !has('ttyin')
    return 'TTY is required.'
  endif

  let action_spy = Spy({ candidate, context -> 0 })

  let [ui, ui_spies] = SpyDict(CreateMockUI({
  \   'is_active': 1,
  \   'pattern': 'VIM',
  \ }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })

  let kind = session.source.default_kind
  let kind.action_table.default = action_spy.to_funcref()

  call assert_true(1, luis#take_action(session, 'default'))

  let expected_candidate = {
  \   'word': 'VIM',
  \   'user_data': {},
  \ }
  let expected_context = {
  \   'action': kind.action_table.default,
  \   'action_name': 'default',
  \   'kind': kind,
  \   'session': session,
  \ }

  call assert_equal(1, ui_spies.quit.call_count())
  call assert_equal(1, ui_spies.guess_candidate.call_count())
  call assert_equal(0, ui_spies.guess_candidate.last_return_value())

  call assert_equal(1, source_spies.on_action.call_count())
  call assert_equal([expected_candidate, expected_context], source_spies.on_action.last_args())
  call assert_equal(source, source_spies.on_action.last_self())
  call assert_equal(1, source_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_leave.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_leave.last_self())

  call assert_equal(1, hook_spies.on_action.call_count())
  call assert_equal([expected_candidate, expected_context], hook_spies.on_action.last_args())
  call assert_equal(hook, hook_spies.on_action.last_self())
  call assert_equal(1, hook_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_leave.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_leave.last_self())

  call assert_equal(1, action_spy.call_count())
  call assert_equal([expected_candidate, expected_context], action_spy.last_args())
  call assert_equal(0, action_spy.last_return_value())
endfunction

function! s:test_take_action__with_no_such_action() abort
  if !has('nvim') && !has('ttyin')
    return 'TTY is required.'
  endif

  let action_spy = Spy({ candidate, context -> 0 })
  let candidate = { 'word': 'VIM', 'user_data': {} }

  let [ui, ui_spies] = SpyDict(CreateMockUI({
  \   'candidate': candidate,
  \   'is_active': 1,
  \ }))
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = luis#new_session(source, {
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': hook,
  \   'initial_pattern': '',
  \ })
  let kind = session.source.default_kind
  let kind.action_table.default = action_spy.to_funcref()

  redir => OUTPUT
  silent call assert_false(luis#take_action(session, 'XXX'))
  redir END

  call assert_match("No such action: 'XXX'", OUTPUT)

  let expected_context = {
  \   'kind': source.default_kind,
  \   'session': session,
  \ }

  call assert_equal(1, ui_spies.quit.call_count())
  call assert_equal(1, ui_spies.guess_candidate.call_count())

  call assert_equal(0, source_spies.on_action.call_count())
  call assert_equal(1, source_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_leave.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_leave.last_self())

  call assert_equal(0, hook_spies.on_action.call_count())
  call assert_equal(1, hook_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_leave.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_leave.last_self())

  call assert_equal(0, action_spy.call_count())
endfunction
