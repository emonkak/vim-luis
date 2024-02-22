let s:kind = luis#kind#text#import()

function! s:test_action_open() abort
  enew
  call setline(1, 'Hello!')
  normal! $
  try
    let Action = s:kind.action_table.open
    silent call Action({ 'word': ' Vim' }, {})
    call assert_equal(['Hello Vim!'], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_action_open_x() abort
  enew
  call setline(1, 'Hello!')
  normal! $
  try
    let Action = s:kind.action_table['open!']
    silent call Action({ 'word': ' Vim' }, {})
    call assert_equal(['Hello! Vim'], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('text', s:kind.name)
endfunction
