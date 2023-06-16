function! s:test_gather_candidates() abort
  try
    let source = luis#source#help#import()

    let context = { 'pattern': 'help' }
    let candidates = source.gather_candidates(context)

    let expected_candidates = map(
    \   getcompletion(context.pattern, 'help'),
    \   '{ "word": v:val }'
    \ )
    call assert_equal(expected_candidates, candidates)
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#help#import()
  call assert_true(luis#_validate_source(source))
  call assert_equal('help', source.name)
endfunction

