let s:kind = luis#kind#help#import()

function! s:test_action_open() abort
  new
  try
    let Action = s:kind.action_table.open
    silent let _ = Action({ 'word': 'usr_01.txt' }, {})
    call assert_equal(0, _)
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
    silent let _ = Action({ 'word': 'usr_01.txt' }, {})
    call assert_match('\<E37:', _)
  finally
    close!
    silent %bwipeout!
  endtry
endfunction

function! s:test_action_open__no_help() abort
  new
  try
    let Action = s:kind.action_table.open
    silent let _ = Action({ 'word': '@@INVALID_ENTRY@@' }, {})
    call assert_match('\<E149:', _)
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
    silent let _ = Action({ 'word': 'usr_01.txt' }, {})
    call assert_equal(0, _)
    call assert_equal('usr_01.txt', fnamemodify(bufname('%'), ':t'))
    call assert_equal('help', &buftype)
  finally
    close!
    silent %bwipeout!
  endtry
endfunction

function! s:test_kind_definition() abort
  call assert_true(luis#_validate_kind(s:kind))
  call assert_equal('help', s:kind.name)
endfunction
