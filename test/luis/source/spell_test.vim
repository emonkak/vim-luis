function! s:test_gather_candidates() abort
  try
    let source = luis#source#spell#new()

    let context = { 'pattern': 'hello' }
    0verbose let candidates = source.gather_candidates(context)

    let expected_candidates = map(
    \   spellsuggest(context.pattern),
    \   '{ "word": v:val }'
    \ )
    call assert_equal(expected_candidates, candidates)
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#spell#new()
  call assert_true(luis#validations#validate_source(source))
  call assert_equal('spell', source.name)
endfunction
