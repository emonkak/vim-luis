function! s:test_gather_candidates() abort
  cgetexpr ['A:12:foo', 'B:24:bar', 'B:36:bar', 'D:baz']
  call assert_equal([1, 1, 1, 0], map(getqflist(), 'v:val.valid'))

  let bufnr_A = bufnr('A')
  let bufnr_B = bufnr('B')

  call assert_equal([bufnr_A, bufnr_B, bufnr_B, 0], map(getqflist(), 'v:val.bufnr'))

  try
    let source = luis#source#quickfix#new()

    call source.on_source_enter({})

    let context = { 'pattern': 'VIM' }
    " Returns candidates in arbitrary order.
    let candidates = sort(source.gather_candidates(context), { x, y ->
    \   x.word < y.word ? -1 : x.word > y.word ? 1 : 0
    \ })

    call assert_equal([
    \   {
    \     'word': 'A',
    \     'menu': '1 errors',
    \     'user_data': { 'buffer_nr': bufnr_A, 'buffer_pos': [12, 0], 'quickfix_nr': 1 },
    \     'luis_sort_priority': 0,
    \   },
    \   {
    \     'word': 'B',
    \     'menu': '2 errors',
    \     'user_data': { 'buffer_nr': bufnr_B, 'buffer_pos': [24, 0], 'quickfix_nr': 2 },
    \     'luis_sort_priority': 1,
    \   },
    \ ], candidates)
  finally
    cgetexpr []
    silent execute 'bwipeout' bufnr_A bufnr_B
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#quickfix#new()
  let errors = luis#_validate_source(source)
  call assert_equal([], errors)
  call assert_equal('quickfix', source.name)
endfunction
