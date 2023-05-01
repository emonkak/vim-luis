let s:kind = g:luis#kind#file#export

function! s:test_action_cd() abort
  call s:do_test_cd(0, 'cd', '/', [])
  call s:do_test_cd(0, 'cd', tempname(), [])
  call s:do_test_cd('Vim(cd):E344:', 'cd', tempname() . '/', [])
endfunction

function! s:test_action_lcd() abort
  call s:do_test_cd(0, 'lcd', '/', [0])
  call s:do_test_cd('Vim(lcd):E344:', 'lcd', tempname() . '/', [0])
endfunction

function! s:test_action_tcd() abort
  if !exists(':tcd')
    return ':tcd comamnd is required.'
  endif
  call s:do_test_cd(0, 'tcd', '/', [-1, 0])
  call s:do_test_cd('Vim(tcd):E344:', 'tcd', tempname() . '/', [-1, 0])
endfunction

function! s:test_action_open() abort
  call s:do_test_open(0, 'open', {})
  call s:do_test_open('Vim(edit):E37:', 'open', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_no_file() abort
  let _ = luis#do_action(s:kind, 'open', {
  \   'word': '',
  \   'user_data': {},
  \ })
  call assert_equal('No file chosen', _)
endfunction

function! s:test_action_open_x() abort
  call s:do_test_open(0, 'open!', {})
  call s:do_test_open(0, 'open!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_x_no_file() abort
  let _ = luis#do_action(s:kind, 'open', {
  \   'word': '',
  \   'user_data': {},
  \ })
  call assert_equal('No file chosen', _)
endfunction

function! s:test_kind_definition() abort
  call assert_equal('file', s:kind.name)
  call assert_true(type(s:kind.action_table), v:t_dict)
  call assert_true(type(s:kind.key_table), v:t_dict)
  call assert_equal(s:kind.prototype, g:luis#kind#common#export)
endfunction

function! s:do_test_cd(expected_result, action_name, path, getcwd_args) abort
  for candidate in [
  \   { 'word': a:path, 'user_data': {} },
  \   { 'word': '', 'user_data': { 'file_path': a:path } },
  \ ]
    let original_cwd = call('getcwd', a:getcwd_args)
    let _ = luis#do_action(s:kind, a:action_name, candidate)
    if type(_) is v:t_string
      call assert_match(a:expected_result, _)
      call assert_equal(original_cwd, call('getcwd', a:getcwd_args))
    else
      call assert_equal(a:expected_result, _)
      call assert_equal(fnamemodify(a:path, ':p:h'), call('getcwd', a:getcwd_args))
      silent execute a:action_name original_cwd
    endif
  endfor
endfunction

function! s:do_test_open(expected_result, action_name, buf_options) abort
  let path = expand('$VIMRUNTIME/doc/help.txt')
  for candidate in [
  \   { 'word': path, 'user_data': { 'file_pos': [4, 1] } },
  \   { 'word': '', 'user_data': { 'file_path': path, 'file_pos': [4, 1] } },
  \ ]
    let bufnr = s:new_buffer(a:buf_options)
    try
      silent let _ = luis#do_action(s:kind, a:action_name, candidate)
      if type(a:expected_result) is v:t_string
        call assert_match(a:expected_result, _)
      else
        call assert_equal(a:expected_result, _)
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
