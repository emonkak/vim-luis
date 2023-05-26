function! s:test_gather_candidates__empty_list() abort
  let source = luis#source#args#new()

  call source.on_source_enter({})

  let candidates = source.gather_candidates({})
  call assert_equal([], candidates)
endfunction

function! s:test_gather_candidates__filled_list() abort
  argadd A B C
  call assert_equal(3, argc())
  call assert_equal(['A', 'B', 'C'], argv())

  let bufnr_A = bufnr('A')
  let bufnr_B = bufnr('B')
  let bufnr_C = bufnr('C')
  call assert_notequal(0, bufnr_A)
  call assert_notequal(0, bufnr_B)
  call assert_notequal(0, bufnr_C)
  call assert_equal(3, len(uniq([bufnr_A, bufnr_B, bufnr_C])))

  try
    let source = luis#source#args#new()

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': 'A',
    \     'user_data': {
    \       'args_index': 0,
    \       'preview_bufnr': bufnr_A,
    \     },
    \   },
    \   {
    \     'word': 'B',
    \     'user_data': {
    \       'args_index': 1,
    \       'preview_bufnr': bufnr_B,
    \     },
    \   },
    \   {
    \     'word': 'C',
    \     'user_data': {
    \       'args_index': 2,
    \       'preview_bufnr': bufnr_C,
    \     },
    \   },
    \ ], candidates)
  finally
    argdelete *
    silent execute 'bwipeout' bufnr_A bufnr_B bufnr_C
    call assert_equal(0, argc())
    call assert_equal([], argv())
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#args#new()
  call assert_equal(1, luis#validations#validate_source(source))
endfunction