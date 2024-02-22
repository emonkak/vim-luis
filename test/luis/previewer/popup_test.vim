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
    let previewer = luis#previewer#popup#new()

    call assert_false(previewer.is_active())

    let bounds = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
    silent call previewer.open_buffer(bufnr_1, bounds, {})

    let preview_win_1 = previewer._window
    let preview_bufnr_1 = winbufnr(previewer._window)

    call assert_true(previewer.is_active())
    call assert_notequal(0, preview_win_1)
    call assert_equal(bufnr_1, preview_bufnr_1)
    call assert_equal(bounds, previewer.bounds())
    call assert_equal(1, get(get(getwininfo(preview_win_1), 0, {}), 'topline'))

    let bounds = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }
    silent call previewer.open_buffer(bufnr_2, bounds, { 'cursor': [10, 1] })

    let preview_win_2 = previewer._window
    let preview_bufnr_2 = winbufnr(previewer._window)

    call assert_true(previewer.is_active())
    call assert_notequal(0, preview_win_2)
    call assert_notequal(preview_win_1, preview_win_2)
    call assert_equal(bufnr_2, preview_bufnr_2)
    call assert_equal(bounds, previewer.bounds())
    call assert_equal(10, get(get(getwininfo(preview_win_2), 0, {}), 'topline'))

    call previewer.close()

    call assert_false(previewer.is_active())
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
    let previewer = luis#previewer#popup#new()

    call assert_false(previewer.is_active())

    let bounds = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
    call previewer.open_buffer(bufnr, bounds, {})

    let preview_win_1 = previewer._window
    let preview_bufnr_1 = winbufnr(previewer._window)

    call assert_true(previewer.is_active())
    call assert_notequal(0, preview_win_1)
    call assert_equal(bufnr, preview_bufnr_1)
    call assert_equal(bounds, previewer.bounds())
    call assert_equal(1, get(get(getwininfo(preview_win_1), 0, {}), 'topline'))
    call assert_equal('', getbufvar(preview_bufnr_1, '&syntax'))

    let lines = ['foo', 'bar', 'baz']
    let bounds = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }

    call previewer.open_text(lines, bounds, {})

    let preview_win_2 = previewer._window
    let preview_bufnr_2 = winbufnr(previewer._window)

    call assert_true(previewer.is_active())
    call assert_notequal(0, preview_win_2)
    call assert_notequal(preview_win_1, preview_win_2)
    call assert_notequal(0, preview_bufnr_2)
    call assert_notequal(preview_bufnr_1, preview_bufnr_2)
    call assert_equal(lines, getbufline(preview_bufnr_2, 1, '$'))
    call assert_equal(bounds, previewer.bounds())
    call assert_equal(1, get(get(getwininfo(preview_win_2), 0, {}), 'topline'))
    call assert_equal('', getbufvar(preview_bufnr_2, '&syntax'))

    call previewer.close()

    call assert_false(previewer.is_active())

    execute preview_bufnr_2 'bwipeout!'
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_open_text__after_unload_preview_buffer() abort
  if !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  let previewer = luis#previewer#popup#new()

  call assert_false(previewer.is_active())

  let lines = ['foo', 'bar', 'baz']
  let bounds = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }

  call previewer.open_text(lines, bounds, {})

  let preview_win_1 = previewer._window
  let preview_bufnr_1 = winbufnr(previewer._window)

  call assert_true(previewer.is_active())
  call assert_notequal(0, preview_win_1)
  call assert_notequal(0, preview_bufnr_1)
  call assert_equal(lines, getbufline(preview_bufnr_1, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal(1, get(get(getwininfo(preview_win_1), 0, {}), 'topline'))
  call assert_equal('', getbufvar(preview_bufnr_1, '&syntax'))

  execute preview_bufnr_1 'bunload!'

  let lines = ['qux', 'quux', 'corge']
  let bounds = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }

  call previewer.open_text(lines, bounds, {})

  let preview_win_2 = previewer._window
  let preview_bufnr_2 = winbufnr(previewer._window)

  call assert_true(previewer.is_active())
  call assert_equal(preview_win_1, preview_win_2)
  call assert_equal(preview_bufnr_1, preview_bufnr_2)
  call assert_equal(lines, getbufline(preview_bufnr_2, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal(1, get(get(getwininfo(preview_win_2), 0, {}), 'topline'))
  call assert_equal('', getbufvar(preview_bufnr_2, '&syntax'))

  call previewer.close()

  call assert_false(previewer.is_active())

  execute preview_bufnr_1 'bwipeout!'
endfunction

function! s:test_open_text__open_twice() abort
  if !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  let previewer = luis#previewer#popup#new()

  call assert_false(previewer.is_active())

  let lines = ['foo', 'bar', 'baz']
  let bounds = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }

  call previewer.open_text(lines, bounds, {})

  let preview_win_1 = previewer._window
  let preview_bufnr_1 = winbufnr(previewer._window)

  call assert_true(previewer.is_active())
  call assert_notequal(0, preview_win_1)
  call assert_notequal(0, preview_bufnr_1)
  call assert_equal(lines, getbufline(preview_bufnr_1, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal(1, get(get(getwininfo(preview_win_1), 0, {}), 'topline'))
  call assert_equal('', getbufvar(preview_bufnr_1, '&syntax'))

  let lines = ['qux', 'quux', 'corge']
  let bounds = { 'row': 2, 'col': 4, 'width': 6, 'height': 8 }

  call previewer.open_text(lines, bounds, {})

  let preview_win_2 = previewer._window
  let preview_bufnr_2 = winbufnr(previewer._window)

  call assert_true(previewer.is_active())
  call assert_equal(preview_win_1, preview_win_2)
  call assert_equal(preview_bufnr_1, preview_bufnr_2)
  call assert_equal(lines, getbufline(preview_bufnr_2, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal(1, get(get(getwininfo(preview_win_2), 0, {}), 'topline'))
  call assert_equal('', getbufvar(preview_bufnr_2, '&syntax'))

  call previewer.close()

  call assert_false(previewer.is_active())

  execute preview_bufnr_1 'bwipeout!'
endfunction

function! s:test_open_text__with_filetype() abort
  if !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  let previewer = luis#previewer#popup#new()

  call assert_false(previewer.is_active())

  let lines = ['foo', 'bar', 'baz']
  let bounds = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }
  let filetype = 'vim'

  call previewer.open_text(lines, bounds, { 'filetype': filetype })

  let preview_win = previewer._window
  let preview_bufnr = winbufnr(previewer._window)

  call assert_true(previewer.is_active())
  call assert_notequal(0, preview_win)
  call assert_notequal(0, preview_bufnr)
  call assert_equal(lines, getbufline(preview_bufnr, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal(1, get(get(getwininfo(preview_win), 0, {}), 'topline'))
  call assert_equal(filetype, getbufvar(preview_bufnr, '&syntax'))

  call previewer.open_text(lines, bounds, {})

  call assert_true(previewer.is_active())
  call assert_notequal(0, preview_win)
  call assert_notequal(0, preview_bufnr)
  call assert_equal(lines, getbufline(preview_bufnr, 1, '$'))
  call assert_equal(bounds, previewer.bounds())
  call assert_equal(1, get(get(getwininfo(preview_win), 0, {}), 'topline'))
  call assert_equal('', getbufvar(preview_bufnr, '&syntax'))

  call previewer.close()

  call assert_false(previewer.is_active())

  execute preview_bufnr 'bwipeout!'
endfunction

function! s:test_open_text__with_path() abort
  if !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  silent filetype on
  try
    let previewer = luis#previewer#popup#new()

    call assert_false(previewer.is_active())

    let bounds = { 'row': 1, 'col': 3, 'width': 5, 'height': 7 }

    for [lines, path, expected_filetype] in [
    \   [["console.log('Hello World!')"], 'foo.ts', 'typescript'],
    \   [["#!/bin/bash"], 'foo.sh', 'sh'],
    \   [["#!/bin/zsh"], 'foo.sh', 'zsh'],
    \ ]
      call previewer.open_text(lines, bounds, { 'path': path })

      let preview_win = previewer._window
      let preview_bufnr = winbufnr(previewer._window)

      call assert_true(previewer.is_active())
      call assert_notequal(0, preview_win)
      call assert_notequal(0, preview_bufnr)
      call assert_equal(lines, getbufline(preview_bufnr, 1, '$'))
      call assert_equal(bounds, previewer.bounds())
      call assert_equal(1, get(get(getwininfo(preview_win), 0, {}), 'topline'))
      call assert_equal(expected_filetype, getbufvar(preview_bufnr, '&syntax'))
    endfor

    call previewer.close()

    call assert_false(previewer.is_active())

    execute preview_bufnr 'bwipeout!'
  finally
    filetype off
  endtry
endfunction

function! s:test_previewer_definition() abort
  let previewer = luis#previewer#popup#new()
  call luis#_validate_previewer(previewer)
endfunction
