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
    let preview_window = luis#preview_window#floats#new()
    call assert_false(preview_window.is_active())

    let dimensions = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
    call preview_window.open_buffer(bufnr_1, dimensions, {})

    let preview_winnr_1 = preview_window.window
    let preview_bufnr_1 = winbufnr(preview_winnr_1)

    call assert_true(preview_window.is_active())
    call assert_notequal(0, preview_winnr_1)
    call assert_notequal(0, preview_bufnr_1)
    call assert_equal(dimensions, preview_window.dimensions())
    call assert_equal(1, get(get(getwininfo(preview_winnr_1), 0, {}), 'topline'))

    let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
    call preview_window.open_buffer(bufnr_2, dimensions, { 'cursor': [10, 1] })
    let preview_winnr_2 = preview_window.window
    let preview_bufnr_2 = winbufnr(preview_winnr_2)

    call assert_true(preview_window.is_active())
    call assert_equal(preview_winnr_1, preview_winnr_2)
    call assert_equal(bufnr_2, preview_bufnr_2)
    call assert_equal(dimensions, preview_window.dimensions())
    call assert_equal(10, get(get(getwininfo(preview_winnr_2), 0, {}), 'topline'))

    call preview_window.close()

    call assert_false(preview_window.is_active())
  finally
    silent execute 'bwipeout!' bufnr_1 bufnr_2 
  endtry
endfunction

function! s:test_open_text__open_twice() abort
  if !exists('*nvim_open_win')
    return 'nvim_open_win() function is required.'
  endif

  let preview_window = luis#preview_window#floats#new()
  call assert_false(preview_window.is_active())

  let lines = ['foo', 'bar', 'baz']
  let dimensions = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
  call preview_window.open_text(lines, dimensions, {})

  let preview_winnr_1 = preview_window.window
  let preview_bufnr_1 = winbufnr(preview_winnr_1)

  call assert_true(preview_window.is_active())
  call assert_notequal(0, preview_winnr_1)
  call assert_notequal(0, preview_bufnr_1)
  call assert_equal(lines, getbufline(preview_bufnr_1, 1, '$'))
  call assert_equal(dimensions, preview_window.dimensions())
  call assert_equal('', getbufvar(preview_bufnr_1, '&filetype'))
  call assert_equal(1, get(get(getwininfo(preview_winnr_1), 0, {}), 'topline'))

  let lines = ['qux', 'quux', 'corge']
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
  call preview_window.open_text(lines, dimensions, { 'filetype': 'vim' })

  let preview_winnr_2 = preview_window.window
  let preview_bufnr_2 = winbufnr(preview_winnr_2)

  call assert_true(preview_window.is_active())
  call assert_equal(preview_winnr_1, preview_winnr_2)
  call assert_equal(preview_bufnr_1, preview_bufnr_2)
  call assert_equal(lines, getbufline(preview_bufnr_2, 1, '$'))
  call assert_equal(dimensions, preview_window.dimensions())
  call assert_equal('vim', getbufvar(preview_bufnr_2, '&filetype'))
  call assert_equal(1, get(get(getwininfo(preview_winnr_2), 0, {}), 'topline'))

  call preview_window.close()

  call assert_false(preview_window.is_active())

  execute preview_bufnr_1 'bwipeout!'
endfunction

function! s:test_open_text__after_unload_open_buffer() abort
  if !exists('*nvim_open_win')
    return 'nvim_open_win() function is required.'
  endif

  let preview_window = luis#preview_window#floats#new()
  call assert_false(preview_window.is_active())

  let lines = ['foo', 'bar', 'baz']
  let dimensions = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
  call preview_window.open_text(lines, dimensions, {})

  let preview_winnr_1 = preview_window.window
  let preview_bufnr_1 = winbufnr(preview_window.window)

  call assert_true(preview_window.is_active())
  call assert_notequal(0, preview_winnr_1)
  call assert_notequal(0, preview_bufnr_1)
  call assert_equal(lines, getbufline(preview_bufnr_1, 1, '$'))
  call assert_equal(dimensions, preview_window.dimensions())
  call assert_equal(1, get(get(getwininfo(preview_winnr_1), 0, {}), 'topline'))

  execute preview_bufnr_1 'bunload!'

  let lines = ['qux', 'quux', 'corge']
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
  call preview_window.open_text(lines, dimensions, {})

  let preview_winnr_2 = preview_window.window
  let preview_bufnr_2 = winbufnr(preview_window.window)

  call assert_true(preview_window.is_active())
  call assert_notequal(preview_winnr_1, preview_winnr_2)
  call assert_notequal(0, preview_winnr_2)
  call assert_equal(preview_bufnr_1, preview_bufnr_2)
  call assert_equal(lines, getbufline(preview_bufnr_2, 1, '$'))
  call assert_equal(dimensions, preview_window.dimensions())
  call assert_equal(1, get(get(getwininfo(preview_winnr_2), 0, {}), 'topline'))

  call preview_window.close()

  call assert_false(preview_window.is_active())

  execute preview_bufnr_1 'bwipeout!'
endfunction
