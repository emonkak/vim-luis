let s:kind = g:luis#kind#buffer#export

function! s:test_action_delete() abort
  call s:do_test_delete(0, 1, 0, 0, 'delete', {})
  call s:do_test_delete('Vim(bdelete):E89:', 1, 1, 1, 'delete', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_delete_x() abort
  call s:do_test_delete(0, 1, 0, 0, 'delete!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open() abort
  call s:do_test_open(0, 'open', {})
  call s:do_test_open('Vim(buffer):E37:', 'open', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_no__corresponding_buffer() abort
  let _ = luis#internal#do_action(s:kind, 'open', {
  \   'word': tempname(),
  \   'user_data': {},
  \ })
  call assert_notequal(0, _)
endfunction

function! s:test_action_open_x() abort
  call s:do_test_open(0, 'open!', {})
  call s:do_test_open(0, 'open!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_x__no_corresponding_buffer() abort
  let _ = luis#internal#do_action(s:kind, 'open!', {
  \   'word': tempname(),
  \   'user_data': {},
  \ })
  call assert_notequal(0, _)
endfunction

function! s:test_action_unload() abort
  call s:do_test_delete(0, 1, 1, 0, 'unload', {})
  call s:do_test_delete('Vim(bunload):E89:', 1, 1, 1, 'unload', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_unload_x() abort
  call s:do_test_delete(0, 1, 1, 0, 'unload!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_wipeout() abort
  call s:do_test_delete(0, 0, 0, 0, 'wipeout', {})
  call s:do_test_delete('Vim(bwipeout):E89:', 1, 1, 1, 'wipeout', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_wipeout_x() abort
  call s:do_test_delete(0, 0, 0, 0, 'wipeout!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_kind_definition() abort
  call assert_equal([], luis#internal#validate_kind(s:kind))
  call assert_equal('buffer', s:kind.name)
endfunction

function! s:assert_buffer(expected_bufexists, expected_buflisted, expected_bufloaded, bufnr) abort
  call assert_equal([
  \   a:expected_bufexists,
  \   a:expected_buflisted,
  \   a:expected_bufloaded,
  \ ], [bufexists(a:bufnr), buflisted(a:bufnr), bufloaded(a:bufnr)])
endfunction

function! s:do_test_delete(expected_result, expected_bufexists, expected_buflisted, expected_bufloaded, action_name, buf_options) abort
  for MakeCandidate in [
  \   { bufnr -> { 'word': bufname(bufnr), 'user_data': {} } },
  \   { bufnr -> { 'word': '', 'user_data': { 'buffer_nr': bufnr } } }
  \ ]
    let bufnr_1 = s:new_buffer({ '&bufhidden': 'hide' })
    let bufnr_2 = s:new_buffer(a:buf_options)
    try
      let candidate = MakeCandidate(bufnr_2)
      let _ = luis#internal#do_action(s:kind, a:action_name, candidate)
      if type(a:expected_result) is v:t_string
        call assert_match(a:expected_result, _)
        call assert_equal(bufnr_2, bufnr('%'))
      else
        call assert_equal(0, _)
        call assert_equal(bufnr_1, bufnr('%'))
      endif
      call s:assert_buffer(a:expected_bufexists, a:expected_buflisted, a:expected_bufloaded, bufnr_2)
    finally
      silent! execute bufnr_2 'bwipeout!'
      silent! execute bufnr_1 'bwipeout!'
    endtry
  endfor
endfunction

function! s:do_test_open(expected_result, action_name, buf_options) abort
  for MakeCandidate in [
  \   { bufnr -> { 'word': bufname(bufnr), 'user_data': { 'buffer_pos': [4, 1] } } },
  \   { bufnr -> { 'word': '', 'user_data': { 'buffer_nr': bufnr, 'buffer_pos': [4, 1] } } }
  \ ]
    let bufnr_1 = s:new_buffer({ '&bufhidden': 'hide' })
    call setline(1, range(1, 10))
    let bufnr_2 = s:new_buffer(a:buf_options)
    try
      let candidate = MakeCandidate(bufnr_1)
      let _ = luis#internal#do_action(s:kind, a:action_name, candidate)
      if type(a:expected_result) is v:t_string
        call assert_match(a:expected_result, _)
        call assert_equal(bufnr_2, bufnr('%'))
      else
        call assert_equal(0, _)
        call assert_equal(bufnr_1, bufnr('%'))
        call assert_equal([4, 1], getpos('.')[1:2])
      endif
    finally
      silent execute bufnr_2 'bwipeout!'
      silent execute bufnr_1 'bwipeout!'
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
