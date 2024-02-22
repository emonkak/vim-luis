let s:kind = luis#kind#buffer#import()

function! s:test_action_delete() abort
  call s:do_test_delete('', 1, 0, 0, 'delete', {})
  call s:do_test_delete(':E89:', 1, 1, 1, 'delete', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_delete_x() abort
  call s:do_test_delete('', 1, 0, 0, 'delete!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open() abort
  call s:do_test_open('', 'open', {})
  call s:do_test_open(':E37:', 'open', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open__no_corresponding_buffer() abort
  let Action = s:kind.action_table.open
  call s:assert_exception(
  \   'There is no corresponding buffer to candidate:',
  \   { -> Action({ 'word': tempname(), 'user_data': {} }, {}) }
  \ )
endfunction

function! s:test_action_open_x() abort
  call s:do_test_open('', 'open!', {})
  call s:do_test_open('', 'open!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_x__no_corresponding_buffer() abort
  let Action = s:kind.action_table['open!']
  call s:assert_exception(
  \   'There is no corresponding buffer to candidate:',
  \   { -> Action({ 'word': tempname(), 'user_data': {} }, {}) }
  \ )
endfunction

function! s:test_action_unload() abort
  call s:do_test_delete('', 1, 1, 0, 'unload', {})
  call s:do_test_delete(':E89:', 1, 1, 1, 'unload', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_unload_x() abort
  call s:do_test_delete('', 1, 1, 0, 'unload!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_wipeout() abort
  call s:do_test_delete('', 0, 0, 0, 'wipeout', {})
  call s:do_test_delete(':E89:', 1, 1, 1, 'wipeout', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_wipeout_x() abort
  call s:do_test_delete('', 0, 0, 0, 'wipeout!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('buffer', s:kind.name)
endfunction

function! s:assert_buffer(expected_bufexists, expected_buflisted, expected_bufloaded, bufnr) abort
  call assert_equal([
  \   a:expected_bufexists,
  \   a:expected_buflisted,
  \   a:expected_bufloaded,
  \ ], [bufexists(a:bufnr), buflisted(a:bufnr), bufloaded(a:bufnr)])
endfunction

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function should have throw exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction

function! s:do_test_delete(expected_exception, expected_bufexists, expected_buflisted, expected_bufloaded, action_name, buf_options) abort
  for MakeCandidate in [
  \   { bufnr -> { 'word': bufname(bufnr), 'user_data': {} } },
  \   { bufnr -> { 'word': '', 'user_data': { 'buffer_nr': bufnr } } }
  \ ]
    let bufnr_1 = s:new_buffer({ '&bufhidden': 'hide' })
    let bufnr_2 = s:new_buffer(a:buf_options)
    try
      let Action = s:kind.action_table[a:action_name]
      let candidate = MakeCandidate(bufnr_2)
      if a:expected_exception != ''
        call s:assert_exception(a:expected_exception, { -> Action(candidate, {}) })
        call assert_equal(bufnr_2, bufnr('%'))
      else
        call Action(candidate, {})
        call assert_equal(bufnr_1, bufnr('%'))
      endif
      call s:assert_buffer(a:expected_bufexists, a:expected_buflisted, a:expected_bufloaded, bufnr_2)
    finally
      silent! execute 'bwipeout!' bufnr_1 bufnr_2
    endtry
  endfor
endfunction

function! s:do_test_open(expected_exception, action_name, buf_options) abort
  for MakeCandidate in [
  \   { bufnr -> { 'word': bufname(bufnr), 'user_data': { 'buffer_cursor': [4, 1] } } },
  \   { bufnr -> { 'word': '', 'user_data': { 'buffer_nr': bufnr, 'buffer_cursor': [4, 1] } } }
  \ ]
    let bufnr_1 = s:new_buffer({ '&bufhidden': 'hide' })
    call setline(1, range(1, 10))
    let bufnr_2 = s:new_buffer(a:buf_options)
    try
      let Action = s:kind.action_table[a:action_name]
      let candidate = MakeCandidate(bufnr_1)
      if a:expected_exception != ''
        call s:assert_exception(a:expected_exception, { -> Action(candidate, {}) })
        call assert_equal(bufnr_2, bufnr('%'))
      else
        call Action(candidate, {})
        call assert_equal(bufnr_1, bufnr('%'))
        call assert_equal([4, 1], getpos('.')[1:2])
      endif
    finally
      silent! execute 'bwipeout!' bufnr_1 bufnr_2
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
