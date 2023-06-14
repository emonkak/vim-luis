let s:source = luis#source#spell#import()

function! s:test_gather_candidates() abort
  try
    let context = { 'pattern': 'hello' }
    0verbose let candidates = s:source.gather_candidates(context)

    let expected_candidates = map(
    \   spellsuggest(context.pattern),
    \   '{ "word": v:val }'
    \ )
    call assert_equal(expected_candidates, candidates)
  endtry
endfunction

function! s:test_source_definition() abort
  call assert_true(luis#validate_source(s:source))
  call assert_equal('spell', s:source.name)
endfunction
