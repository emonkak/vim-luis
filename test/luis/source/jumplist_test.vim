function! s:test_gather_candidates() abort
  if !exists('*getjumplist')
    return 'getjumplist() function is required.'
  endif

  let bufname = tempname()
  silent split `=bufname`
  let bufnr = bufnr('%')
  let window = win_getid()

  call setline(1, range(1, 10))
  clearjumps
  normal! 2gg
  normal! 4gg
  normal! 8gg
  normal! 10gg
  execute 'normal!' "\<C-o>"

  call assert_equal([1, 2, 4, 8, 10], map(getjumplist()[0], 'v:val.lnum'))

  try
    let source = luis#source#jumplist#new(window)

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': bufname . ':1:0',
    \     'menu': 'jump 1',
    \     'kind': '',
    \     'user_data': {
    \       'buffer_cursor': [1, 0],
    \       'buffer_nr': bufnr,
    \       'jumplist_location': 0,
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [1, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 0,
    \   },
    \   {
    \     'word': bufname . ':2:0',
    \     'menu': 'jump 2',
    \     'kind': '',
    \     'user_data': {
    \       'buffer_cursor': [2, 0],
    \       'buffer_nr': bufnr,
    \       'jumplist_location': 1,
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [2, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -1,
    \   },
    \   {
    \     'word': bufname . ':4:0',
    \     'menu': 'jump 3',
    \     'kind': '',
    \     'user_data': {
    \       'buffer_cursor': [4, 0],
    \       'buffer_nr': bufnr,
    \       'jumplist_location': 2,
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [4, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -2,
    \   },
    \   {
    \     'word': bufname . ':8:0',
    \     'menu': 'jump 4',
    \     'kind': '*',
    \     'user_data': {
    \       'buffer_nr': bufnr,
    \       'buffer_cursor': [8, 0],
    \       'jumplist_location': 3,
    \       'preview_bufnr': bufnr,
    \       'preview_cursor': [8, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': -3,
    \   },
    \   {
    \     'word': bufname . ':10:0',
    \     'menu': 'jump 5',
    \     'kind': '',
    \     'user_data': {
    \       'buffer_nr': bufnr,
    \       'buffer_cursor': [10, 0],
    \       'jumplist_location': 4,
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
  let source = luis#source#jumplist#new(win_getid())
  call assert_equal(1, luis#validations#validate_source(source))
  call assert_equal('jumplist', source.name)
endfunction
