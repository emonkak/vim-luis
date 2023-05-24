function! s:test_gather_candidates__empty_list() abort
  let source = luis#source#args#new()

  call source.on_source_enter({})

  let candidates = source.gather_candidates({})
  call assert_equal([], candidates)
endfunction

function! s:test_gather_candidates__filled_list() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  try
    let source = luis#source#args#new()

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    let expected_candidates = map(argv(), '{
    \   "word": v:val,
    \   "user_data": { "args_index": v:key },
    \ }')
    call assert_equal(expected_candidates, candidates)
  finally
    argdelete *
    silent %bwipeout
    call assert_equal(0, argc())
    call assert_equal([], argv())
  endtry
endfunction

function! s:test_preview_candidate() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  let bufnr_foo = bufnr('foo')
  let bufnr_bar = bufnr('bar')
  let bufnr_baz = bufnr('baz')

  call assert_equal(3, len(uniq([bufnr_foo, bufnr_bar, bufnr_baz])))
  call assert_notequal(0, bufnr_foo)
  call assert_notequal(0, bufnr_bar)
  call assert_notequal(0, bufnr_baz)

  try
    let source = luis#source#args#new()

    let candidate = {
    \  'word': 'foo',
    \ }
    silent call assert_equal(
    \   { 'type': 'buffer', 'bufnr': bufnr_foo },
    \   source.preview_candidate(candidate, {})
    \ )

    let candidate = {
    \  'word': 'bar',
    \ }
    silent call assert_equal(
    \   { 'type': 'buffer', 'bufnr': bufnr_bar },
    \   source.preview_candidate(candidate, {})
    \ )

    let candidate = {
    \  'word': 'baz',
    \ }
    silent call assert_equal(
    \   { 'type': 'buffer', 'bufnr': bufnr_baz },
    \   source.preview_candidate(candidate, {})
    \ )

    let candidate = {
    \  'word': 'XXX',
    \  'user_data': {},
    \ }
    silent call assert_equal(
    \   { 'type': 'none' },
    \   source.preview_candidate(candidate, {})
    \ )
  finally
    argdelete *
    silent %bwipeout
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#args#new()
  call assert_equal(1, luis#validations#validate_source(source))
endfunction
