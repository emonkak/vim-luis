silent packadd vim-metarw
silent packadd vim-metarw-dummy

function! s:test_gather_candidates() abort
  let metarw_candidates = [
  \   'dummy:foo:',
  \   'dummy:foo:bar/',
  \   'dummy:foo:bar/baz',
  \ ]
  let spy = Spy({ -> [metarw_candidates, '', ''] })

  function! metarw#dummy#complete(arglead, cmdline, cursorpos) abort closure
    return spy.call([a:arglead, a:cmdline, a:cursorpos])
  endfunction

  try
    let scheme = 'dummy'
    let pattern = 'VIM'
    let source = luis#source#metarw#new(scheme)

    let candidates = source.gather_candidates({ 'pattern': pattern })
    call assert_equal([
    \   {
    \     'word': 'foo',
    \     'abbr': 'foo:',
    \     'user_data': { 'file_path': 'dummy:foo:' },
    \   },
    \   {
    \     'word': 'foo:bar',
    \     'abbr': 'foo:bar/',
    \     'user_data': { 'file_path': 'dummy:foo:bar/' },
    \   },
    \   {
    \     'word': 'foo:bar/baz',
    \     'abbr': 'foo:bar/baz',
    \     'user_data': { 'file_path': 'dummy:foo:bar/baz' },
    \   },
    \ ], candidates)
    call assert_equal(1, spy.call_count())
    call assert_equal(
    \   [scheme . ':' . pattern, scheme . ':' . pattern, 0],
    \   spy.last_args()
    \ )
    call assert_equal(
    \   [metarw_candidates, '', ''],
    \   spy.last_return_value()
    \ )
  finally
    silent runtime! autoload/metarw/dummy.vim
  endtry
endfunction

function! s:test_is_valid_for_acc() abort
  let scheme = 'dummy'
  let source = luis#source#metarw#new(scheme)
  let separator = exists('+shellslash') && !&shellslash ? '\' : '/'

  call assert_false(source.is_valid_for_acc({}))
  call assert_false(source.is_valid_for_acc({ 'word': 'master:foo', 'abbr': 'master:foo' }))
  call assert_true(source.is_valid_for_acc({ 'word': 'master:bar', 'abbr': 'master:bar/' }))
endfunction

function! s:test_is_component_separator() abort
  let scheme = 'dummy'
  let source = luis#source#metarw#new(scheme)
  let separator = exists('+shellslash') && !&shellslash ? '\' : '/'

  call assert_true(source.is_component_separator(separator))
  call assert_true(source.is_component_separator(':'))
  call assert_false(source.is_component_separator('A'))
endfunction

function! s:test_on_action() abort
  let scheme = 'dummy'
  let source = luis#source#metarw#new(scheme)
  let candidate = {
  \   'word': 'foo:bar',
  \   'user_data': {},
  \ }

  call source.on_action(candidate, {})

  call assert_equal({
  \   'word': 'foo:bar',
  \   'user_data': {
  \     'file_path': scheme . ':foo:bar',
  \   },
  \ }, candidate)
endfunction

function! s:test_source_definition() abort
  let source = luis#source#metarw#new('dummy')
  call luis#_validate_source(source)
  call assert_equal('metarw/dummy', source.name)
endfunction
