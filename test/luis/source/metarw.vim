silent packadd vim-metarw
silent packadd vim-metarw-dummy

function s:test_gather_candidates() abort
  let spy = Spy(funcref('metarw#dummy#complete'))

  let metarw_candidates = [
  \   'dummy:foo:',
  \   'dummy:foo:bar/',
  \   'dummy:foo:bar/baz',
  \ ]
  call spy.override({ _ -> [metarw_candidates, '', ''] })

  function! metarw#dummy#complete(arglead, cmdline, cursorpos) abort closure
    return spy.call([a:arglead, a:cmdline, a:cursorpos])
  endfunction

  try
    let scheme = 'dummy'
    let pattern = 'XXX'
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
    call assert_equal([{
    \   'args': [scheme . ':' . pattern, scheme . ':' . pattern, 0],
    \   'return_value': [metarw_candidates, '', ''],
    \ }], spy.calls())
  finally
    call spy.restore()
  endtry
endfunction

function s:test_on_action() abort
  let scheme = 'dummy'
  let source = luis#source#metarw#new(scheme)
  let candidate = {
  \   'word': 'foo:bar',
  \   'user_data': {},
  \ }

  call source.on_action(candidate)

  call assert_equal({
  \   'word': 'foo:bar',
  \   'user_data': {
  \     'file_path': scheme . ':foo:bar',
  \   },
  \ }, candidate)
endfunction

function s:test_is_special_char() abort
  let scheme = 'dummy'
  let source = luis#source#metarw#new(scheme)
  let separator = exists('+shellslash') && !&shellslash ? '\' : '/'

  call assert_true(source.is_special_char(separator))
  call assert_true(source.is_special_char(':'))
  call assert_false(source.is_special_char('A'))
endfunction

function s:test_source_definition() abort
  let source = luis#source#metarw#new('dummy')
  let schema = luis#_scope().SCHEMA_SOURCE
  let errors = luis#schema#validate(schema, source)
  call assert_equal([], errors)
  call assert_equal('metarw/dummy', source.name)
endfunction
