function s:test_gather_candidates() abort
  enew
  setlocal foldmethod=marker
  call setline(1, [
  \   '" Foo {{{1',
  \   '',
  \   'echo "foo"',
  \   '',
  \   '" Bar {{{1',
  \   '',
  \   'echo "bar"',
  \   '',
  \   '" Baz {{{',
  \   'echo "baz"',
  \   '" }}}',
  \ ])
  let bufnr = bufnr('%')
  new

  try
    let source = luis#source#fold#new()

    call source.on_source_enter()

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': '" Foo',
    \     'abbr': '" Foo',
    \     'menu': '4 lines',
    \     'dup': 1,
    \     'user_data': { 'fold_lnum': 1 },
    \     'luis_sort_priority': 1,
    \   },
    \   {
    \     'word': '" Bar',
    \     'abbr': '" Bar',
    \     'menu': '7 lines',
    \     'dup': 1,
    \     'user_data': { 'fold_lnum': 5 },
    \     'luis_sort_priority': 5,
    \   },
    \   {
    \     'word': '" Baz',
    \     'abbr': '  " Baz',
    \     'menu': '3 lines',
    \     'dup': 1,
    \     'user_data': { 'fold_lnum': 9 },
    \     'luis_sort_priority': 9,
    \   },
    \ ], candidates)
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function s:test_source_definition() abort
  let source = luis#source#fold#new()
  let errors = luis#internal#validate_source(source)
  call assert_equal([], errors)
  call assert_equal('fold', source.name)
endfunction
