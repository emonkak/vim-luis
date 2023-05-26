silent runtime! test/mocks.vim
silent runtime! test/spy.vim

function! s:test_attach_window__invalid_window() abort
  let v:errmsg = ''
  silent! call luis#preview#attach_window({})
  call assert_match('luis: Invalid Preview:', v:errmsg)
  call assert_false(luis#preview#is_enabled())
endfunction

function! s:test_attach_window__valid_window() abort
  let [preview_window_1, preview_window_1_spies] = SpyDict(CreateMockPreviewWindow(1))
  let [preview_window_2, preview_window_2_spies] = SpyDict(CreateMockPreviewWindow(0))

  call assert_equal(0, luis#preview#attach_window(preview_window_1))
  call assert_true(luis#preview#is_enabled())
  call assert_true(luis#preview#is_active())
  call assert_equal(0, preview_window_1_spies.close.call_count())
  call assert_equal(0, preview_window_2_spies.close.call_count())

  try
    call assert_true(luis#preview#attach_window(preview_window_2) is preview_window_1)
    call assert_true(luis#preview#is_enabled())
    call assert_false(luis#preview#is_active())
    call assert_equal(1, preview_window_1_spies.close.call_count())
    call assert_equal(0, preview_window_2_spies.close.call_count())
  finally
    call assert_true(luis#preview#detach_window() is preview_window_2)
    call assert_false(luis#preview#is_enabled())
    call assert_false(luis#preview#is_active())
    call assert_equal(1, preview_window_1_spies.close.call_count())
    call assert_equal(1, preview_window_2_spies.close.call_count())
  endtry
endfunction

function! s:test_detect_filetype() abort
  if !has('nvim') && !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  filetype on

  try
    call assert_equal('', luis#preview#detect_filetype('foo'))
    call assert_equal('c', luis#preview#detect_filetype('foo.c'))
    call assert_equal('javascript', luis#preview#detect_filetype('foo.js'))
    call assert_equal('vim', luis#preview#detect_filetype('foo.vim'))
  finally
    filetype off
  endtry
endfunction

function! s:test_quit__enabled() abort
  let [preview_window, preview_window_spies] = SpyDict(CreateMockPreviewWindow(1))

  call assert_equal(0, luis#preview#attach_window(preview_window))
  call assert_true(luis#preview#is_enabled())

  try
    call assert_equal(1, luis#preview#quit())
    call assert_equal(1, preview_window_spies.close.call_count())
  finally
    call assert_true(luis#preview#detach_window() is preview_window)
    call assert_false(luis#preview#is_enabled())
  endtry
endfunction

function! s:test_quit__not_enabled() abort
  let v:errmsg = ''
  silent! call luis#preview#quit()
  call assert_equal('luis: Preview not available', v:errmsg)
endfunction

function! s:test_start__not_enabled() abort
  let source = SpyDict(CreateMockSource())
  let hook = SpyDict(CreateMockHook())
  let session = CreateMockSession(source, hook, {}, 1)
  let dimensions = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }

  let v:errmsg = ''
  silent! call luis#preview#start(session, dimensions)
  call assert_equal('luis: Preview not available', v:errmsg)
endfunction

function! s:test_start__with_buffer_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [preview_window, preview_window_spies] = SpyDict(CreateMockPreviewWindow(1))

  call assert_equal(0, luis#preview#attach_window(preview_window))
  call assert_true(luis#preview#is_enabled())

  try
    " With existent buffer
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'preview_bufnr': bufnr('%'),
    \     'preview_cursor': [10, 1],
    \   }
    \ }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let dimensions = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }

    call assert_equal(1, luis#preview#start(session, dimensions))
    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(1, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(1, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(1, preview_window_spies.open_buffer.call_count())
    call assert_equal(
    \   [
    \     candidate.user_data.preview_bufnr,
    \     dimensions,
    \     { 'cursor': candidate.user_data.preview_cursor }
    \   ],
    \   preview_window_spies.open_buffer.last_args()
    \ )
    call assert_equal(0, preview_window_spies.close.call_count())

    " With non-existent buffer
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'preview_bufnr': bufnr('$') + 1,
    \   }
    \ }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let dimensions = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }

    call assert_equal(1, luis#preview#start(session, dimensions))
    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(2, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(2, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(1, preview_window_spies.open_buffer.call_count())
    call assert_equal(1, preview_window_spies.close.call_count())
  finally
    call assert_true(luis#preview#detach_window() is preview_window)
    call assert_false(luis#preview#is_enabled())
  endtry
endfunction

function! s:test_start__with_file_preview() abort
  if !has('nvim') && !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [preview_window, preview_window_spies] = SpyDict(CreateMockPreviewWindow(1))

  filetype on

  call assert_equal(0, luis#preview#attach_window(preview_window))
  call assert_true(luis#preview#is_enabled())

  try
    " With filetype
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'preview_path': 'test/data/seq.txt',
    \     'preview_filetype': 'help',
    \   }
    \ }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let dimensions = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }

    call assert_equal(1, luis#preview#start(session, dimensions))
    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(1, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(1, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(1, preview_window_spies.open_text.call_count())
    call assert_equal(
    \   [
    \     ['1', '2', '3', '4'],
    \     dimensions,
    \     { 'filetype': 'help' },
    \   ],
    \   preview_window_spies.open_text.last_args()
    \ )
    call assert_equal(0, preview_window_spies.close.call_count())

    " Without filetype (Auto detection)
    let candidate = {
    \   'word': 'hello_world.vim',
    \   'user_data': {
    \     'preview_path': 'test/data/hello_world.vim',
    \   }
    \ }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let dimensions = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }

    call assert_equal(1, luis#preview#start(session, dimensions))
    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(2, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(2, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(2, preview_window_spies.open_text.call_count())
    call assert_equal(
    \   [
    \     ["echo 'hello, world!'"],
    \     dimensions,
    \     { 'filetype': 'vim' },
    \   ],
    \   preview_window_spies.open_text.last_args()
    \ )
    call assert_equal(0, preview_window_spies.close.call_count())

    " With non-existent file
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'preview_path': tempname(),
    \   }
    \ }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let dimensions = { 'row': 3, 'col': 4, 'width': 5, 'height': 6 }

    call assert_equal(1, luis#preview#start(session, dimensions))
    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(3, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(3, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(2, preview_window_spies.open_text.call_count())
    call assert_equal(1, preview_window_spies.close.call_count())
  finally
    call assert_true(luis#preview#detach_window() is preview_window)
    call assert_false(luis#preview#is_enabled())
    filetype off
  endtry
endfunction

function! s:test_start__with_no_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [preview_window, preview_window_spies] = SpyDict(CreateMockPreviewWindow(1))

  call assert_equal(0, luis#preview#attach_window(preview_window))
  call assert_true(luis#preview#is_enabled())

  try
    let candidate = { 'word': '', 'user_data': {} }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let dimensions = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }

    call assert_equal(1, luis#preview#start(session, dimensions))
    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(1, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(1, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(1, preview_window_spies.close.call_count())
  finally
    call assert_true(luis#preview#detach_window() is preview_window)
    call assert_false(luis#preview#is_enabled())
  endtry
endfunction

function! s:test_start__with_text_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [preview_window, preview_window_spies] = SpyDict(CreateMockPreviewWindow(1))

  call assert_equal(0, luis#preview#attach_window(preview_window))
  call assert_true(luis#preview#is_enabled())

  try
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'preview_title': 'title',
    \     'preview_lines': ['foo', 'bar', 'baz'],
    \   }
    \ }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let dimensions = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }

    call assert_equal(1, luis#preview#start(session, dimensions))
    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(1, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(1, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview_window': preview_window },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(1, preview_window_spies.open_text.call_count())
    call assert_equal(
    \   [
    \     candidate.user_data.preview_lines,
    \     dimensions,
    \     { 'title': candidate.user_data.preview_title }
    \   ],
    \   preview_window_spies.open_text.last_args()
    \ )
    call assert_equal(0, preview_window_spies.close.call_count())
  finally
    call assert_true(luis#preview#detach_window() is preview_window)
    call assert_false(luis#preview#is_enabled())
  endtry
endfunction
