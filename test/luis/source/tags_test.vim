function! s:test_gather_candidates() abort
  new
  lcd test/data

  try
    let source = luis#source#tags#new(win_getid())

    let context = { 'pattern': '' }
    let candidates = source.gather_candidates(context)
    call assert_equal([
    \  { 'word': 'Bar' },
    \  { 'word': 'Baz' },
    \  { 'word': 'Foo' },
    \ ], candidates)

    let context = { 'pattern': 'Foo' }
    let candidates = source.gather_candidates(context)
    call assert_equal([
    \  { 'word': 'Foo' },
    \ ], candidates)
  finally
    close
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#tags#new(win_getid())
  call assert_true(luis#_validate_source(source))
  call assert_equal('tags', source.name)
endfunction
