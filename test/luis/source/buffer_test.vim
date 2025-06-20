function! s:test_gather_candidates() abort
  enew
  let bufnr_1 = bufnr('%')

  silent new `=tempname()`
  let bufnr_2 = bufnr('%')

  silent new `=fnamemodify(tempname(), ':h:t')`
  let bufnr_3 = bufnr('%')

  try
    let source = luis#source#buffer#new()

    call source.on_source_enter({})

    call assert_equal([
    \   {
    \     'word': '[No Name]',
    \     'kind': 'a',
    \     'menu': 'buffer ' . bufnr_1,
    \     'dup': 1,
    \     'user_data': {
    \       'buffer_nr': bufnr_1,
    \       'preview_bufnr': bufnr_1,
    \     },
    \     'luis_sort_priority': -1,
    \   },
    \   {
    \     'word': bufname(bufnr_2),
    \     'kind': '#a',
    \     'menu': 'buffer ' . bufnr_2,
    \     'dup': 0,
    \     'user_data': {
    \       'buffer_nr': bufnr_2,
    \       'preview_bufnr': bufnr_2,
    \     },
    \     'luis_sort_priority': -2,
    \   },
    \   {
    \     'word': bufname(bufnr_3),
    \     'kind': '%a',
    \     'menu': 'buffer ' . bufnr_3,
    \     'dup': 0,
    \     'user_data': {
    \       'buffer_nr': bufnr_3,
    \       'preview_bufnr': bufnr_3,
    \     },
    \     'luis_sort_priority': -3,
    \   },
    \ ], source.gather_candidates({ 'pattern': '' }))
  finally
    silent %bwipeout
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#buffer#new()
  call luis#_validate_source(source)
  call assert_equal('buffer', source.name)
endfunction
