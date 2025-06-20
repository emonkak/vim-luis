function! s:test_gather_candidates() abort
  call histdel('cmd')

  call assert_equal(-1, histnr('cmd'))
  call assert_true(histadd('cmd', 'foo'))
  call assert_true(histadd('cmd', 'bar'))
  call assert_true(histadd('cmd', 'baz'))
  call assert_equal(3, histnr('cmd'))
  call assert_equal('foo', histget('cmd', 1))
  call assert_equal('bar', histget('cmd', 2))
  call assert_equal('baz', histget('cmd', 3))

  try
    let source = luis#source#history#new('cmd')

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': 'foo',
    \     'menu': 'history 1',
    \     'user_data': {
    \       'history_name': 'cmd',
    \       'history_index': 1
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 1,
    \   },
    \   {
    \     'word': 'bar',
    \     'menu': 'history 2',
    \     'user_data': {
    \       'history_name': 'cmd',
    \       'history_index': 2
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 2,
    \   },
    \   {
    \     'word': 'baz',
    \     'menu': 'history 3',
    \     'user_data': {
    \       'history_name': 'cmd',
    \       'history_index': 3
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 3,
    \   }
    \ ], candidates)
  finally
    call histdel('cmd')
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#history#new('cmd')
  call luis#_validate_source(source)
  call assert_equal('history/cmd', source.name)
endfunction
