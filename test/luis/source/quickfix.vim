function s:test_gather_candidates() abort
  cgetexpr ['A:12:foo', 'B:24:bar', 'C:baz']
  call assert_equal([1, 1, 0], map(getqflist(), 'v:val.valid'))
  call assert_equal([bufnr('A'), bufnr('B'), 0], map(getqflist(), 'v:val.bufnr'))

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
    \     'user_data': { 'buffer_nr': bufnr('A'), 'quickfix_nr': 1 },
    \     "luis_sort_priority": 1,
    \   },
    \   {
    \     'word': 'B',
    \     'user_data': { 'buffer_nr': bufnr('B'), 'quickfix_nr': 2 },
    \     "luis_sort_priority": 2,
    \   },
    \ ], candidates)
  finally
    cgetexpr []
    silent bwipeout A
    silent bwipeout B
    call assert_equal([], getqflist())
    call assert_equal(-1, bufnr('A'))
    call assert_equal(-1, bufnr('B'))
  endtry
endfunction

function s:test_source_definition() abort
  let source = luis#source#quickfix#new()
  let errors = luis#_validate_source(source)
  call assert_equal([], errors)
  call assert_equal('quickfix', source.name)
endfunction
