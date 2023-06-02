function! s:test_definition() abort
  let previewer = luis#previewer#floats#new()
  call assert_true(luis#validations#validate_preview(previewer))
endfunction

function! s:test_open_text__after_unload_open_buffer() abort
  if !exists('*nvim_open_win')
    return 'nvim_open_win() function is required.'
  endif

  let previewer = luis#previewer#floats#new()
  call assert_true(previewer.is_available())
  call assert_false(previewer.is_active())

  let lines = ['foo', 'bar', 'baz']
  let bounds = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
  call previewer.open_text(lines, bounds, {})

  let preview_winnr_1 = previewer.window
  let preview_bufnr_1 = winbufnr(previewer.window)

  call assert_true(previewer.is_active())
  call assert_notequal(0, preview_winnr_1)
  call assert_notequal(0, preview_bufnr_1)
  call assert_equal(lines, getbufline(preview_bufnr_1, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal(1, get(get(getwininfo(preview_winnr_1), 0, {}), 'topline'))

  execute preview_bufnr_1 'bunload!'

  let lines = ['qux', 'quux', 'corge']
  let bounds = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
  call previewer.open_text(lines, bounds, {})

  let preview_winnr_2 = previewer.window
  let preview_bufnr_2 = winbufnr(previewer.window)

  call assert_true(previewer.is_active())
  call assert_notequal(preview_winnr_1, preview_winnr_2)
  call assert_notequal(0, preview_winnr_2)
  call assert_equal(preview_bufnr_1, preview_bufnr_2)
  call assert_equal(lines, getbufline(preview_bufnr_2, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal(1, get(get(getwininfo(preview_winnr_2), 0, {}), 'topline'))

  call previewer.close()

  call assert_false(previewer.is_active())

  execute preview_bufnr_1 'bwipeout!'
endfunction

function! s:test_open_text__open_twice() abort
  if !exists('*nvim_open_win')
    return 'nvim_open_win() function is required.'
  endif

  let previewer = luis#previewer#floats#new()
  call assert_false(previewer.is_active())

  let lines = ['foo', 'bar', 'baz']
  let bounds = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
  call previewer.open_text(lines, bounds, {})

  let preview_winnr_1 = previewer.window
  let preview_bufnr_1 = winbufnr(preview_winnr_1)

  call assert_true(previewer.is_active())
  call assert_notequal(0, preview_winnr_1)
  call assert_notequal(0, preview_bufnr_1)
  call assert_equal(lines, getbufline(preview_bufnr_1, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal('', getbufvar(preview_bufnr_1, '&filetype'))
  call assert_equal(1, get(get(getwininfo(preview_winnr_1), 0, {}), 'topline'))

  let lines = ['qux', 'quux', 'corge']
  let bounds = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
  call previewer.open_text(lines, bounds, { 'filetype': 'vim' })

  let preview_winnr_2 = previewer.window
  let preview_bufnr_2 = winbufnr(preview_winnr_2)

  call assert_true(previewer.is_active())
  call assert_equal(preview_winnr_1, preview_winnr_2)
  call assert_equal(preview_bufnr_1, preview_bufnr_2)
  call assert_equal(lines, getbufline(preview_bufnr_2, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal('vim', getbufvar(preview_bufnr_2, '&filetype'))
  call assert_equal(1, get(get(getwininfo(preview_winnr_2), 0, {}), 'topline'))

  call previewer.close()

  call assert_false(previewer.is_active())

  execute preview_bufnr_1 'bwipeout!'
endfunction

function! s:test_preview_buffer__preview_twice() abort
  if !exists('*nvim_open_win')
    return 'nvim_open_win() function is required.'
  endif

  silent edit `=tempname()`
  let bufnr_1 = bufnr('%')

  silent edit `=tempname()`
  call setline(1, range(100))
  let bufnr_2 = bufnr('%')

  try
    let previewer = luis#previewer#floats#new()
    call assert_false(previewer.is_active())

    let bounds = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
    call previewer.open_buffer(bufnr_1, bounds, {})

    let preview_winnr_1 = previewer.window
    let preview_bufnr_1 = winbufnr(preview_winnr_1)

    call assert_true(previewer.is_active())
    call assert_notequal(0, preview_winnr_1)
    call assert_notequal(0, preview_bufnr_1)
    call assert_equal(bounds, previewer.bounds())
    call assert_equal(1, get(get(getwininfo(preview_winnr_1), 0, {}), 'topline'))

    let bounds = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
    call previewer.open_buffer(bufnr_2, bounds, { 'cursor': [10, 1] })
    let preview_winnr_2 = previewer.window
    let preview_bufnr_2 = winbufnr(preview_winnr_2)

    call assert_true(previewer.is_active())
    call assert_equal(preview_winnr_1, preview_winnr_2)
    call assert_equal(bufnr_2, preview_bufnr_2)
    call assert_equal(bounds, previewer.bounds())
    call assert_equal(10, get(get(getwininfo(preview_winnr_2), 0, {}), 'topline'))

    call previewer.close()

    call assert_false(previewer.is_active())
  finally
    silent execute 'bwipeout!' bufnr_1 bufnr_2 
  endtry
endfunction