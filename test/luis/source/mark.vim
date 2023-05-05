function s:test_gather_candidates() abort
  if !exists('*getmarklist')
    return 'getmarklist() function is required.'
  endif

  enew
  let bufname = tempname()
  silent file `=bufname`
  call setline(1, range(1, 100))
  let bufnr = bufnr('%')

  delmarks!
  normal 1ggma
  normal 20ggmb
  normal 40ggmc
  normal 60ggmd
  normal 80ggme
  new

  try
    let source = luis#source#mark#new()

    call source.on_source_enter()

    let candidates = source.gather_candidates({})
    call assert_equal([
    \ {
    \   'word': bufname . ':1:1',
    \   'menu': 'mark a',
    \   'user_data': { 'mark_name': 'a' },
    \   'dup': 1,
    \   'luis_sort_priority': char2nr('a'),
    \ },
    \ {
    \   'word': bufname . ':20:1',
    \   'menu': 'mark b',
    \   'user_data': { 'mark_name': 'b' },
    \   'dup': 1,
    \   'luis_sort_priority': char2nr('b'),
    \ },
    \ {
    \   'word': bufname . ':40:1',
    \   'menu': 'mark c',
    \   'user_data': { 'mark_name': 'c' },
    \   'dup': 1,
    \   'luis_sort_priority': char2nr('c'),
    \ },
    \ {
    \   'word': bufname . ':60:1',
    \   'menu': 'mark d',
    \   'user_data': { 'mark_name': 'd' },
    \   'dup': 1,
    \   'luis_sort_priority': char2nr('d'),
    \ },
    \ {
    \   'word': bufname . ':80:1',
    \   'menu': 'mark e',
    \   'user_data': { 'mark_name': 'e' },
    \   'dup': 1,
    \   'luis_sort_priority': char2nr('e'),
    \ },
    \ {
    \   'word': bufname . ':1:1',
    \   'menu': 'mark ''',
    \   'user_data': { 'mark_name': '''' },
    \   'dup': 1,
    \   'luis_sort_priority': char2nr("'"),
    \ },
    \ {
    \   'word': bufname . ':1:1',
    \   'menu': 'mark "',
    \   'user_data': { 'mark_name': '"' },
    \   'dup': 1,
    \   'luis_sort_priority': char2nr('"'),
    \ }
    \ ], candidates)
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function s:test_source_definition() abort
  let source = luis#source#mark#new()
  let schema = luis#_scope().SCHEMA_SOURCE
  let errors = luis#schema#validate(schema, source)
  call assert_equal([], errors)
  call assert_equal('mark', source.name)
endfunction
