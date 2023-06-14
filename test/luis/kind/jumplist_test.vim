let s:kind = luis#kind#jumplist#import()

function! s:test_action_open() abort
  if !exists('*getjumplist')
    return 'getjumplist() function is required.'
  endif

  new
  call setline(1, range(1, 10))
  clearjumps
  normal! 2gg
  normal! 4gg
  normal! 8gg
  normal! 10gg
  execute 'normal!' "\<C-o>"

  call assert_equal([1, 2, 4, 8, 10], map(getjumplist()[0], 'v:val.lnum'))
  call assert_equal(8, line('.'))

  let Action = s:kind.action_table.open

  try
    let candidate = {
    \   'user_data': {
    \     'jumplist_location': 4,
    \   },
    \ }
    let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(10, line('.'))

    let candidate = {
    \   'user_data': {
    \     'jumplist_location': 2,
    \   },
    \ }
    let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(4, line('.'))

    let candidate = {
    \   'user_data': {
    \     'jumplist_location': 0,
    \   },
    \ }
    let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(1, line('.'))

    let candidate = {
    \   'user_data': {
    \     'jumplist_location': 3,
    \   },
    \ }
    let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(8, line('.'))
  finally
    bwipeout!
  endtry
endfunction
