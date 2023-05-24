silent runtime! test/mocks.vim
silent runtime! test/spy.vim

function! s:test_close() abort
  let [preview, preview_spies] = SpyDict(CreateMockPreview(1))

  call assert_equal(0, luis#preview#enable(preview))
  call assert_true(luis#preview#is_enabled())

  call luis#preview#close()

  call assert_equal(1, preview_spies.close.call_count())

  call assert_true(luis#preview#disable() is preview)
  call assert_false(luis#preview#is_enabled())

  call assert_equal(1, preview_spies.close.call_count())
endfunction

function! s:test_enable__invalid_preview() abort
  let v:errmsg = ''
  silent! call luis#preview#enable({})
  call assert_match('luis: Invalid Preview:', v:errmsg)
  call assert_false(luis#preview#is_enabled())
endfunction

function! s:test_enable__valid_preview() abort
  let preview_1 = CreateMockPreview(1)
  let preview_2 = CreateMockPreview(0)

  call assert_equal(0, luis#preview#enable(preview_1))
  call assert_true(luis#preview#is_enabled())
  call assert_true(luis#preview#is_active())

  call assert_true(luis#preview#enable(preview_2) is preview_1)
  call assert_true(luis#preview#is_enabled())
  call assert_false(luis#preview#is_active())

  call assert_true(luis#preview#disable() is preview_2)
  call assert_false(luis#preview#is_enabled())
  call assert_false(luis#preview#is_active())
endfunction

function! s:test_open__buffer() abort
  let [preview, preview_spies] = SpyDict(CreateMockPreview(1))
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }

  call assert_equal(0, luis#preview#enable(preview))
  call assert_true(luis#preview#is_enabled())

  let content = { 'type': 'buffer', 'bufnr': 12, 'lnum': 34 }
  call luis#preview#open(content, dimensions)

  call assert_equal(1, preview_spies.open_buffer.call_count())
  call assert_equal(
  \   [content.bufnr, content.lnum, dimensions],
  \   preview_spies.open_buffer.last_args()
  \ )

  let content = { 'type': 'buffer', 'bufnr': 12 }
  call luis#preview#open(content, dimensions)

  call assert_equal(2, preview_spies.open_buffer.call_count())
  call assert_equal(
  \   [content.bufnr, 0, dimensions],
  \   preview_spies.open_buffer.last_args()
  \ )

  call assert_true(luis#preview#disable() is preview)
  call assert_false(luis#preview#is_enabled())
endfunction

function! s:test_open__none() abort
  let [preview, preview_spies] = SpyDict(CreateMockPreview(1))
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }

  call assert_equal(0, luis#preview#enable(preview))
  call assert_true(luis#preview#is_enabled())

  let content = { 'type': 'none' }
  call luis#preview#open(content, dimensions)

  call assert_equal(1, preview_spies.close.call_count())

  call assert_true(luis#preview#disable() is preview)
  call assert_false(luis#preview#is_enabled())
endfunction

function! s:test_open__text() abort
  let [preview, preview_spies] = SpyDict(CreateMockPreview(1))
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }

  call assert_equal(0, luis#preview#enable(preview))
  call assert_true(luis#preview#is_enabled())

  let content = { 'type': 'text', 'lines': ['foo', 'bar', 'baz'] }
  call luis#preview#open(content, dimensions)

  call assert_equal(1, preview_spies.open_text.call_count())
  call assert_equal(
  \   [content.lines, dimensions],
  \   preview_spies.open_text.last_args()
  \ )

  call assert_true(luis#preview#disable() is preview)
  call assert_false(luis#preview#is_enabled())
endfunction
