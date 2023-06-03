function! s:test_gather_candidates() abort
  let source = luis#source#tags#new([getcwd() . '/test/data/tags'])

  call source.on_source_enter({})

  let candidates = source.gather_candidates({})
  call assert_equal([
  \  {
  \    'word': 'Foo()',
  \    'menu': 'foo.vim',
  \    'dup': 1
  \  },
  \  {
  \    'word': 'Bar()',
  \    'menu': 'bar.vim',
  \    'dup': 1
  \  },
  \  {
  \    'word': 'Baz()',
  \    'menu': 'baz.vim',
  \    'dup': 1
  \  }
  \ ], candidates)
endfunction

function! s:test_source_definition() abort
  let source = luis#source#tags#new([])
  call assert_true(luis#validate_source(source))
  call assert_equal('tags', source.name)
endfunction
