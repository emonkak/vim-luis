let s:kind = luis#kind#help#import()

function! s:test_action_open() abort
  new
  try
    let Action = s:kind.action_table.open
    silent call Action({ 'word': 'usr_01.txt' }, {})
    call assert_equal('usr_01.txt', fnamemodify(bufname('%'), ':t'))
    call assert_equal('help', &buftype)
  finally
    close
    silent %bwipeout!
  endtry
endfunction

function! s:test_action_open__in_modified_buffer() abort
  new
  setlocal modified
  try
    let Action = s:kind.action_table.open
    call s:assert_exception(
    \   ':E37:',
    \   { -> Action({ 'word': 'usr_01.txt' }, {}) }
    \ )
  finally
    close!
    silent %bwipeout!
  endtry
endfunction

function! s:test_action_open__no_help() abort
  new
  try
    let Action = s:kind.action_table.open
    call s:assert_exception(
    \   ':E149:',
    \   { -> Action({ 'word': '@@INVALID_ENTRY@@' }, {}) }
    \ )
  finally
    close
    silent %bwipeout!
  endtry
endfunction

function! s:test_action_open_x() abort
  new
  setlocal modified
  try
    let Action = s:kind.action_table.open_x
    silent call Action({ 'word': 'usr_01.txt' }, {})
    call assert_equal('usr_01.txt', fnamemodify(bufname('%'), ':t'))
    call assert_equal('help', &buftype)
  finally
    close!
    silent %bwipeout!
  endtry
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('help', s:kind.name)
endfunction

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function should have throw exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction
