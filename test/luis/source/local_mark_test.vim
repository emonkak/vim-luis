function! s:test_gather_candidates() abort
  if !exists('*getmarklist')
    return 'getmarklist() function is required.'
  endif

  let bufname = tempname()
  silent edit `=bufname`
  let bufnr = bufnr('%')
  call setline(1, range(1, 100))

  delmarks!
  normal 1ggma
  normal 20ggmb
  normal 40ggmc

  try
    let source = luis#source#local_mark#new(bufnr)

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': bufname . ':1:1',
    \     'menu': 'mark a',
    \     'user_data': {
    \       'mark_name': 'a',
    \       'mark_pos': [1, 1],
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [1, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('a'),
    \   },
    \   {
    \     'word': bufname . ':20:1',
    \     'menu': 'mark b',
    \     'user_data': {
    \       'mark_name': 'b',
    \       'mark_pos': [20, 1],
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [20, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('b'),
    \   },
    \   {
    \     'word': bufname . ':40:1',
    \     'menu': 'mark c',
    \     'user_data': {
    \       'mark_name': 'c',
    \       'mark_pos': [40, 1],
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [40, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('c'),
    \   },
    \   {
    \     'word': bufname . ':20:1',
    \     'menu': "mark '",
    \     'user_data': {
    \       'mark_name': "'",
    \       'mark_pos': [20, 1],
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [20, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr("'"),
    \   },
    \   {
    \     'word': bufname . ':1:1',
    \     'menu': 'mark "',
    \     'user_data': {
    \       'mark_name': '"',
    \       'mark_pos': [1, 1],
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [1, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('"'),
    \   }
    \ ], candidates)
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#local_mark#new(123)
  call assert_true(luis#_validate_source(source))
  call assert_equal('local_mark', source.name)
endfunction
