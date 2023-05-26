function! s:test_open_buffer__open_twice() abort
  if !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  silent edit `=tempname()`
  let bufnr_1 = bufnr('%')

  silent edit `=tempname()`
  call setline(1, range(100))
  let bufnr_2 = bufnr('%')

  try
    let preview = luis#preview_win#popup#new()

    call assert_false(preview.is_active())

    let dimensions = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
    silent call preview.open_buffer(bufnr_1, dimensions, {})

    let wininfo_1 = get(getwininfo(preview.window), 0, {})
    call assert_false(empty(wininfo_1))
    if empty(wininfo_1)
      return
    endif

    call assert_true(preview.is_active())
    call assert_equal(0, wininfo_1.winnr)
    call assert_equal(bufnr_1, wininfo_1.bufnr)
    call assert_equal(dimensions.row + 1, wininfo_1.winrow)
    call assert_equal(dimensions.col, wininfo_1.wincol)
    call assert_equal(dimensions.width, wininfo_1.width)
    call assert_equal(dimensions.height, wininfo_1.height)

    let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
    silent call preview.open_buffer(bufnr_2, dimensions, { 'cursor': [10, 1] })

    let wininfo_2 = get(getwininfo(preview.window), 0, {})
    call assert_false(empty(wininfo_2))
    if empty(wininfo_2)
      return
    endif

    call assert_true(preview.is_active())
    call assert_equal(wininfo_1.winnr, wininfo_2.winnr)
    call assert_equal(bufnr_2, wininfo_2.bufnr)
    call assert_equal(dimensions.row + 1, wininfo_2.winrow)
    call assert_equal(dimensions.col, wininfo_2.wincol)
    call assert_equal(dimensions.width, wininfo_2.width)
    call assert_equal(dimensions.height, wininfo_2.height)
    call assert_equal(10, wininfo_2.topline)

    call preview.close()

    call assert_false(preview.is_active())
  finally
    silent execute 'bwipeout!' bufnr_1 bufnr_2 
  endtry
endfunction

function! s:test_open_text__after_open_buffer() abort
  if !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  silent edit `=tempname()`
  let bufnr = bufnr('%')

  try
    let preview_win = luis#preview_win#popup#new()

    call assert_false(preview_win.is_active())

    let dimensions = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
    call preview_win.open_buffer(bufnr, dimensions, {})

    let wininfo_1 = get(getwininfo(preview_win.window), 0, {})
    call assert_false(empty(wininfo_1))
    if empty(wininfo_1)
      return
    endif

    call assert_true(preview_win.is_active())
    call assert_equal(0, wininfo_1.winnr)
    call assert_equal(bufnr, wininfo_1.bufnr)
    call assert_equal(dimensions.row + 1, wininfo_1.winrow)
    call assert_equal(dimensions.col, wininfo_1.wincol)
    call assert_equal(dimensions.width, wininfo_1.width)
    call assert_equal(dimensions.height, wininfo_1.height)
    call assert_equal(1, wininfo_1.topline)

    let lines = ['foo', 'bar', 'baz']
    let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
    call preview_win.open_text(lines, dimensions, {})

    let wininfo_2 = get(getwininfo(preview_win.window), 0, {})
    call assert_false(empty(wininfo_2))
    if empty(wininfo_2)
      return
    endif

    call assert_true(preview_win.is_active())
    call assert_equal(wininfo_1.winnr, wininfo_2.winnr)
    call assert_notequal(0, wininfo_2.bufnr)
    call assert_notequal(wininfo_1.bufnr, wininfo_2.bufnr)
    call assert_equal(lines, getbufline(wininfo_2.bufnr, 1, '$'))
    call assert_equal(dimensions.row + 1, wininfo_2.winrow)
    call assert_equal(dimensions.col, wininfo_2.wincol)
    call assert_equal(dimensions.width, wininfo_2.width)
    call assert_equal(dimensions.height, wininfo_2.height)
    call assert_equal(1, wininfo_2.topline)

    call preview_win.close()

    call assert_false(preview_win.is_active())

    execute wininfo_2.bufnr 'bwipeout'
  finally
    execute bufnr 'bwipeout'
  endtry
endfunction

function! s:test_open_text__after_unload_preview_buffer() abort
  if !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  let preview_win = luis#preview_win#popup#new()

  call assert_false(preview_win.is_active())

  let lines = ['foo', 'bar', 'baz']
  let dimensions = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
  call preview_win.open_text(lines, dimensions, {})

  let wininfo_1 = get(getwininfo(preview_win.window), 0, {})
  call assert_false(empty(wininfo_1))
  if empty(wininfo_1)
    return
  endif

  call assert_true(preview_win.is_active())
  call assert_equal(0, wininfo_1.winnr)
  call assert_notequal(0, wininfo_1.bufnr)
  call assert_equal(lines, getbufline(wininfo_1.bufnr, 1, '$'))
  call assert_equal(dimensions.row + 1, wininfo_1.winrow)
  call assert_equal(dimensions.col, wininfo_1.wincol)
  call assert_equal(dimensions.width, wininfo_1.width)
  call assert_equal(dimensions.height, wininfo_1.height)
  call assert_equal(1, wininfo_1.topline)

  execute wininfo_1.bufnr 'bdelete'

  let lines = ['qux', 'quux', 'corge']
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
  call preview_win.open_text(lines, dimensions, {})

  let wininfo_2 = get(getwininfo(preview_win.window), 0, {})
  call assert_false(empty(wininfo_2))
  if empty(wininfo_2)
    return
  endif

  call assert_true(preview_win.is_active())
  call assert_equal(wininfo_1.winnr, wininfo_2.winnr)
  call assert_notequal(0, wininfo_2.bufnr)
  call assert_equal(lines, getbufline(wininfo_2.bufnr, 1, '$'))
  call assert_equal(dimensions.row + 1, wininfo_2.winrow)
  call assert_equal(dimensions.col, wininfo_2.wincol)
  call assert_equal(dimensions.width, wininfo_2.width)
  call assert_equal(dimensions.height, wininfo_2.height)
  call assert_equal(1, wininfo_2.topline)

  call preview_win.close()

  call assert_false(preview_win.is_active())

  execute wininfo_2.bufnr 'bwipeout'
endfunction

function! s:test_open_text__open_twice() abort
  if !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  let preview_win = luis#preview_win#popup#new()

  call assert_false(preview_win.is_active())

  let lines = ['foo', 'bar', 'baz']
  let dimensions = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
  call preview_win.open_text(lines, dimensions, {})

  let wininfo_1 = get(getwininfo(preview_win.window), 0, {})
  call assert_false(empty(wininfo_1))
  if empty(wininfo_1)
    return
  endif

  call assert_true(preview_win.is_active())
  call assert_equal(0, wininfo_1.winnr)
  call assert_notequal(0, wininfo_1.bufnr)
  call assert_equal(lines, getbufline(wininfo_1.bufnr, 1, '$'))
  call assert_equal(dimensions.row + 1, wininfo_1.winrow)
  call assert_equal(dimensions.col, wininfo_1.wincol)
  call assert_equal(dimensions.width, wininfo_1.width)
  call assert_equal(dimensions.height, wininfo_1.height)
  call assert_equal(1, wininfo_1.topline)

  let lines = ['qux', 'quux', 'corge']
  let dimensions = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
  call preview_win.open_text(lines, dimensions, {})

  let wininfo_2 = get(getwininfo(preview_win.window), 0, {})
  call assert_false(empty(wininfo_2))
  if empty(wininfo_2)
    return
  endif

  call assert_true(preview_win.is_active())
  call assert_equal(wininfo_1.winnr, wininfo_2.winnr)
  call assert_equal(wininfo_1.bufnr, wininfo_2.bufnr)
  call assert_equal(lines, getbufline(wininfo_2.bufnr, 1, '$'))
  call assert_equal(dimensions.row + 1, wininfo_2.winrow)
  call assert_equal(dimensions.col, wininfo_2.wincol)
  call assert_equal(dimensions.width, wininfo_2.width)
  call assert_equal(dimensions.height, wininfo_2.height)
  call assert_equal(1, wininfo_2.topline)

  call preview_win.close()

  call assert_false(preview_win.is_active())

  execute wininfo_1.bufnr 'bwipeout' 
endfunction
