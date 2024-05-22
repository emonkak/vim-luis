function! s:test_gather_candidates() abort
  if !exists('*getchangelist')
    return 'getchangelist() function is required.'
  endif

  let bufname = tempname()
  silent split `=bufname`
  let bufnr = bufnr('%')

  keepjumps call setline(1, range(1, 10))
  call feedkeys("1ggi\<Space>\<BS>", 'ntx')
  call feedkeys("2ggi\<Space>\<BS>", 'ntx')
  call feedkeys("4ggi\<Space>\<BS>", 'ntx')
  call feedkeys("8ggi\<Space>\<BS>", 'ntx')
  call feedkeys("10ggi\<Space>\<BS>", 'ntx')
  normal! 2g;

  call assert_equal(
  \   [[1, 0], [2, 0], [4, 0], [8, 0], [10, 0]],
  \   map(get(getchangelist(bufnr), 0, []), '[v:val.lnum, v:val.col]')
  \ )
  call assert_equal(3, get(getchangelist(bufnr), 1, -1))
  call assert_equal(8, line('.'))

  try
    let source = luis#source#changelist#new(bufnr)

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': bufname . ':1:0',
    \     'menu': 'change 1',
    \     'kind': '',
    \     'user_data': {
    \       'buffer_cursor': [1, 0],
    \       'buffer_nr': bufnr,
    \       'changelist_index': 0,
    \       'changelist_bufnr': bufnr,
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [1, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 0,
    \   },
    \   {
    \     'word': bufname . ':2:0',
    \     'menu': 'change 2',
    \     'kind': '',
    \     'user_data': {
    \       'buffer_cursor': [2, 0],
    \       'buffer_nr': bufnr,
    \       'changelist_index': 1,
    \       'changelist_bufnr': bufnr,
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [2, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -1,
    \   },
    \   {
    \     'word': bufname . ':4:0',
    \     'menu': 'change 3',
    \     'kind': '',
    \     'user_data': {
    \       'buffer_cursor': [4, 0],
    \       'buffer_nr': bufnr,
    \       'changelist_index': 2,
    \       'changelist_bufnr': bufnr,
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [4, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -2,
    \   },
    \   {
    \     'word': bufname . ':8:0',
    \     'menu': 'change 4',
    \     'kind': '*',
    \     'user_data': {
    \       'buffer_nr': bufnr,
    \       'buffer_cursor': [8, 0],
    \       'changelist_index': 3,
    \       'changelist_bufnr': bufnr,
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [8, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -3,
    \   },
    \   {
    \     'word': bufname . ':10:0',
    \     'menu': 'change 5',
    \     'kind': '',
    \     'user_data': {
    \       'buffer_nr': bufnr,
    \       'buffer_cursor': [10, 0],
    \       'changelist_index': 4,
    \       'changelist_bufnr': bufnr,
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [10, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -4,
    \   },
    \ ], candidates)
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#changelist#new(win_getid())
  call luis#_validate_source(source)
  call assert_equal('changelist', source.name)
endfunction
