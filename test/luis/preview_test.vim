silent runtime! test/mocks.vim
silent runtime! test/spy.vim

function! s:test_attach_window__invalid_window() abort
  let v:errmsg = ''
  silent! call luis#preview#attach_window({})
  call assert_match('luis: Invalid Preview:', v:errmsg)
  call assert_false(luis#preview#is_enabled())
endfunction

function! s:test_attach_window__valid_window() abort
  let [preview_win_1, preview_win_1_spies] = SpyDict(CreateMockPreviewWindow(1))
  let [preview_win_2, preview_win_2_spies] = SpyDict(CreateMockPreviewWindow(0))

  call assert_equal(0, luis#preview#attach_window(preview_win_1))
  call assert_true(luis#preview#is_enabled())
  call assert_true(luis#preview#is_active())
  call assert_equal(0, preview_win_1_spies.quit_preview.call_count())
  call assert_equal(0, preview_win_2_spies.quit_preview.call_count())

  try
    call assert_true(luis#preview#attach_window(preview_win_2) is preview_win_1)
    call assert_true(luis#preview#is_enabled())
    call assert_false(luis#preview#is_active())
    call assert_equal(1, preview_win_1_spies.quit_preview.call_count())
    call assert_equal(0, preview_win_2_spies.quit_preview.call_count())
  finally
    call assert_true(luis#preview#detach_window() is preview_win_2)
    call assert_false(luis#preview#is_enabled())
    call assert_false(luis#preview#is_active())
    call assert_equal(1, preview_win_1_spies.quit_preview.call_count())
    call assert_equal(1, preview_win_2_spies.quit_preview.call_count())
  endtry
endfunction

function! s:test_detect_filetype() abort
  if !exists('*bufadd')
    return 'bufadd() function is required.'
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

function! s:test_quit() abort
  let [preview_win, preview_win_spies] = SpyDict(CreateMockPreviewWindow(1))

  call assert_equal(0, luis#preview#attach_window(preview_win))
  call assert_true(luis#preview#is_enabled())

  try
    call luis#preview#quit()
    call assert_equal(1, preview_win_spies.quit_preview.call_count())
  finally
    call assert_true(luis#preview#detach_window() is preview_win)
    call assert_false(luis#preview#is_enabled())
  endtry
endfunction

function! s:test_start__buffer() abort
  let [preview_win, preview_win_spies] = SpyDict(CreateMockPreviewWindow(1))
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }

  call assert_equal(0, luis#preview#attach_window(preview_win))
  call assert_true(luis#preview#is_enabled())

  try
    let content = { 'type': 'buffer', 'bufnr': 12, 'pos': [34, 56] }
    call luis#preview#start(content, dimensions)

    call assert_equal(1, preview_win_spies.preview_buffer.call_count())
    call assert_equal(
    \   [content.bufnr, dimensions, { 'pos': [34, 56] }],
    \   preview_win_spies.preview_buffer.last_args()
    \ )

    let content = { 'type': 'buffer', 'bufnr': 12 }
    call luis#preview#start(content, dimensions)

    call assert_equal(2, preview_win_spies.preview_buffer.call_count())
    call assert_equal(
    \   [content.bufnr, dimensions, {}],
    \   preview_win_spies.preview_buffer.last_args()
    \ )
  finally
    call assert_true(luis#preview#detach_window() is preview_win)
    call assert_false(luis#preview#is_enabled())
  endtry
endfunction

function! s:test_start__file() abort
  if !exists('*bufadd')
    return 'bufadd() function is required.'
  endif

  let [preview_win, preview_win_spies] = SpyDict(CreateMockPreviewWindow(1))

  filetype on

  call assert_equal(0, luis#preview#attach_window(preview_win))
  call assert_true(luis#preview#is_enabled())

  try
    let content = { 'type': 'file', 'path': 'test/data/hello.vim' }
    let dimensions = { 'row': 1, 'col': 1, 'width': 80, 'height': 3 }
    call luis#preview#start(content, dimensions)

    call assert_equal(1, preview_win_spies.preview_text.call_count())
    call assert_equal(
    \   [
    \     ['echo 1', 'echo 2', 'echo 3'],
    \     dimensions,
    \     { 'filetype': 'vim' },
    \   ],
    \   preview_win_spies.preview_text.last_args()
    \ )

    let content = {
    \   'type': 'file',
    \   'path': 'test/data/hello.vim',
    \   'filetype': '',
    \ }
    let dimensions = { 'row': 1, 'col': 1, 'width': 80, 'height': 2 }
    call luis#preview#start(content, dimensions)

    call assert_equal(2, preview_win_spies.preview_text.call_count())
    call assert_equal(
    \   [
    \     ['echo 1', 'echo 2'],
    \     dimensions,
    \     { 'filetype': '' },
    \   ],
    \   preview_win_spies.preview_text.last_args()
    \ )
  finally
    call assert_true(luis#preview#detach_window() is preview_win)
    call assert_false(luis#preview#is_enabled())
    filetype off
  endtry
endfunction

function! s:test_start__none() abort
  let [preview_win, preview_win_spies] = SpyDict(CreateMockPreviewWindow(1))
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }

  call assert_equal(0, luis#preview#attach_window(preview_win))
  call assert_true(luis#preview#is_enabled())

  try
    let content = { 'type': 'none' }
    call luis#preview#start(content, dimensions)

    call assert_equal(1, preview_win_spies.quit_preview.call_count())
  finally
    call assert_true(luis#preview#detach_window() is preview_win)
    call assert_false(luis#preview#is_enabled())
  endtry
endfunction

function! s:test_start__text() abort
  let [preview_win, preview_win_spies] = SpyDict(CreateMockPreviewWindow(1))
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }

  call assert_equal(0, luis#preview#attach_window(preview_win))
  call assert_true(luis#preview#is_enabled())

  try
    let content = {
    \   'type': 'text',
    \   'lines': ['foo', 'bar', 'baz'],
    \ }
    call luis#preview#start(content, dimensions)

    call assert_equal(1, preview_win_spies.preview_text.call_count())
    call assert_equal(
    \   [content.lines, dimensions, {}],
    \   preview_win_spies.preview_text.last_args()
    \ )

    let content = {
    \   'type': 'text',
    \   'lines': ['foo', 'bar', 'baz'],
    \   'filetype': 'vim',
    \ }
    call luis#preview#start(content, dimensions)

    call assert_equal(2, preview_win_spies.preview_text.call_count())
    call assert_equal(
    \   [content.lines, dimensions, { 'filetype': 'vim' }],
    \   preview_win_spies.preview_text.last_args()
    \ )
  finally
    call assert_true(luis#preview#detach_window() is preview_win)
    call assert_false(luis#preview#is_enabled())
  endtry
endfunction
