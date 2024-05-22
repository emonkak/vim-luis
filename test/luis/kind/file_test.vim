let s:kind = luis#kind#file#import()

function! s:test_action_cd() abort
  call s:do_test_cd('', 'cd', '/', [])
  call s:do_test_cd('', 'cd', tempname(), [])
  call s:do_test_cd(':E344:', 'cd', tempname() . '/', [])
endfunction

function! s:test_action_lcd() abort
  call s:do_test_cd('', 'lcd', '/', [0])
  call s:do_test_cd(':E344:', 'lcd', tempname() . '/', [0])
endfunction

function! s:test_action_tcd() abort
  if !exists(':tcd')
    return ':tcd comamnd is required.'
  endif
  call s:do_test_cd('', 'tcd', '/', [-1, 0])
  call s:do_test_cd(':E344:', 'tcd', tempname() . '/', [-1, 0])
endfunction

function! s:test_action_open() abort
  call s:do_test_open('', 'open', {})
  call s:do_test_open(':E37:', 'open', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open__no_file() abort
  let Action = s:kind.action_table.open
  call s:assert_exception(
  \   'No file chosen',
  \   { -> Action({ 'word': '', 'user_data': {} }, {}) }
  \ )
endfunction

function! s:test_action_open_x() abort
  call s:do_test_open('', 'open!', {})
  call s:do_test_open('', 'open!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_x__no_file() abort
  let Action = s:kind.action_table.open
  call s:assert_exception(
  \   'No file chosen',
  \   { -> Action({ 'word': '', 'user_data': {} }, {}) }
  \ )
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('file', s:kind.name)
endfunction

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function must throw an exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction

function! s:do_test_cd(expected_exception, action_name, path, getcwd_args) abort
  let Action = s:kind.action_table[a:action_name]
  for candidate in [
  \   { 'word': a:path, 'user_data': {} },
  \   { 'word': '', 'user_data': { 'file_path': a:path } },
  \ ]
    let original_cwd = call('getcwd', a:getcwd_args)
    if a:expected_exception != ''
      call s:assert_exception(a:expected_exception, { -> Action(candidate, {}) })
      call assert_equal(original_cwd, call('getcwd', a:getcwd_args))
    else
      call Action(candidate, {})
      call assert_equal(fnamemodify(a:path, ':p:h'), call('getcwd', a:getcwd_args))
      silent execute a:action_name original_cwd
    endif
  endfor
endfunction

function! s:do_test_open(expected_exception, action_name, buf_options) abort
  let path = expand('$VIMRUNTIME/doc/help.txt')
  let Action = s:kind.action_table[a:action_name]
  for candidate in [
  \   { 'word': path, 'user_data': { 'file_cursor': [4, 1] } },
  \   { 'word': '', 'user_data': { 'file_path': path, 'file_cursor': [4, 1] } },
  \ ]
    let bufnr = s:new_buffer(a:buf_options)
    try
      if a:expected_exception != ''
        call s:assert_exception(a:expected_exception, { -> Action(candidate, {}) })
      else
        silent call Action(candidate, {})
        call assert_equal(path, bufname('%'))
        call assert_equal([4, 1], getpos('.')[1:2])
        silent execute 'bwipeout' path
      endif
    finally
      silent execute bufnr 'bwipeout!'
    endtry
  endfor
endfunction

function! s:new_buffer(options) abort
  silent edit `=tempname()`
  let bufnr = bufnr('%')
  for [key, value] in items(a:options)
    call setbufvar(bufnr, key, value)
  endfor
  return bufnr
endfunction
