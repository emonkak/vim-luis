function s:test_gather_candidates__empty_list() abort
  let source = luis#source#args#new()

  call source.on_source_enter({})

  let candidates = source.gather_candidates({})
  call assert_equal(map(argv(), '{ "word": v:val }'), candidates)
endfunction

function s:test_gather_candidates__filled_list() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  try
    let source = luis#source#args#new()

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal(map(argv(), '{ "word": v:val }'), candidates)
  finally
    argdelete *
    silent %bwipeout
    call assert_equal(0, argc())
    call assert_equal([], argv())
  endtry
endfunction

function s:test_source_definition() abort
  let source = luis#source#args#new()
  let errors = luis#_validate_source(source)
  call assert_equal([], errors)
endfunction
