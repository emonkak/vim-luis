function! s:test_gather_candidates() abort
  if !exists('*getmarklist')
    return 'getmarklist() function is required.'
  endif

  let bufname = tempname()
  silent edit `=bufname`
  let bufnr = bufnr('%')
  call setline(1, range(1, 100))

  delmarks!
  normal 1ggmA
  normal 20ggmB
  normal 40ggmC

  try
    let source = luis#source#mark#new()

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': bufname . ':1:1',
    \     'menu': 'mark A',
    \     'user_data': {
    \       'mark_name': 'A',
    \       'mark_pos': [1, 1],
    \       'preview_path': bufname,
    \       'preview_cursor': [1, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('A'),
    \   },
    \   {
    \     'word': bufname . ':20:1',
    \     'menu': 'mark B',
    \     'user_data': {
    \       'mark_name': 'B',
    \       'mark_pos': [20, 1],
    \       'preview_path': bufname,
    \       'preview_cursor': [20, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('B'),
    \   },
    \   {
    \     'word': bufname . ':40:1',
    \     'menu': 'mark C',
    \     'user_data': {
    \       'mark_name': 'C',
    \       'mark_pos': [40, 1],
    \       'preview_path': bufname,
    \       'preview_cursor': [40, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('C'),
    \   },
    \ ], candidates)
  finally
    execute bufnr 'bwipeout!'
    delmarks A-Z
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#mark#new()
  call assert_true(luis#_validate_source(source))
  call assert_equal('mark', source.name)
endfunction
