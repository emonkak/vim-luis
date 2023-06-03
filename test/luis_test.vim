silent runtime! test/spy.vim
silent runtime! test/mocks.vim

function! s:test_acc_text() abort
  let source = CreateMockSource({
  \   'is_valid_for_acc': { candidate ->
  \     get(candidate, 'is_valid_for_acc', 1)
  \   },
  \ })

  let cs1 = [
  \   { 'word': 'usr/share/man/man1' },
  \ ]
  let cs2 = [
  \   { 'word': 'usr/share/w y 1' },
  \   { 'word': 'usr/share/ x z2' },
  \   { 'word': 'usr/share/w y 3' },
  \   { 'word': 'usr/share/ x z4' },
  \ ]
  let cs3 = [
  \   { 'word': 'bin/1/1' },
  \   { 'word': 'etc/2/2' },
  \   { 'word': 'usr/3/3' },
  \   { 'word': 'var/4/4' },
  \ ]
  let cs4 = [
  \   { 'word': '1/X', 'is_valid_for_acc': 0 },
  \   { 'word': '2/X', 'is_valid_for_acc': 0 },
  \   { 'word': '3/X' },
  \   { 'word': '4/X', 'is_valid_for_acc': 0 },
  \ ]

  " len(components) == 2
  call assert_equal('usr', luis#acc_text('/', cs1, source))
  call assert_equal('usr', luis#acc_text('u/', cs1, source))
  call assert_equal('usr', luis#acc_text('s/', cs1, source))
  call assert_equal('usr/share', luis#acc_text('sh/', cs1, source))
  call assert_equal('usr/share/man', luis#acc_text('m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#acc_text('1/', cs1, source))

  call assert_equal('usr/share/w y 1', luis#acc_text('w/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#acc_text('x/', cs2, source))
  call assert_equal('usr/share/w y 1', luis#acc_text('y/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#acc_text('z/', cs2, source))

  call assert_equal('bin', luis#acc_text('b/', cs3, source))
  call assert_equal('etc', luis#acc_text('e/', cs3, source))
  call assert_equal('usr', luis#acc_text('r/', cs3, source))
  call assert_equal('usr', luis#acc_text('u/', cs3, source))
  call assert_equal('var', luis#acc_text('v/', cs3, source))

  call assert_equal('3/X', luis#acc_text('X/', cs4, source))

  " len(components) >= 3
  call assert_equal('usr/share', luis#acc_text('usr//', cs1, source))
  call assert_equal('usr/share', luis#acc_text('usr/s/', cs1, source))
  call assert_equal('usr/share', luis#acc_text('usr/sh/', cs1, source))
  call assert_equal('usr/share/man', luis#acc_text('usr/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#acc_text('usr/1/', cs1, source))
  call assert_equal('usr/share', luis#acc_text('usr/share/', cs1, source))

  call assert_equal('usr/share/man', luis#acc_text('usr/share//', cs1, source))
  call assert_equal('usr/share/man', luis#acc_text('usr/share/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#acc_text('usr/share/1/', cs1, source))

  call assert_equal('etc/2', luis#acc_text('etc//', cs3, source))
  call assert_equal('var/4', luis#acc_text('var//', cs3, source))

  " No components
  let v:errmsg = ''
  silent! call luis#acc_text('', [], source)
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  let v:errmsg = ''
  silent! call assert_equal('', luis#acc_text('', cs1, source))
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  " No proper candidate for a:pattern
  call assert_equal('', luis#acc_text('x/', [], source))
  call assert_equal('', luis#acc_text('x/', cs1, source))
  call assert_equal('', luis#acc_text('2/', cs1, source))
  call assert_equal('', luis#acc_text('u/s/m/', cs1, source))
  call assert_equal('', luis#acc_text('USR//', cs1, source))
endfunction

function! s:test_detect_filetype() abort
  if !has('nvim') && !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  filetype on

  try
    call assert_equal('', luis#detect_filetype('foo', []))
    call assert_equal('c', luis#detect_filetype('foo.c', []))
    call assert_equal('javascript', luis#detect_filetype('foo.js', []))
    call assert_equal('vim', luis#detect_filetype('foo.vim', []))
    call assert_equal('html', luis#detect_filetype('foo.html', ['<!DOCTYPE html>']))
  finally
    filetype off
  endtry
endfunction

function! s:test_do_action__with_defined_action() abort
  let action_spy = Spy({ candidate, context -> 0 })
  let kind = CreateMockKind()
  let kind.action_table.default  = action_spy.to_funcref()
  let session = luis#session#new(
  \   CreateMockFinder(),
  \   CreateMockSource(),
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   CreateMockHook()
  \ )

  let candidate = { 'word': 'VIM' }
  let context = { 'kind': kind, 'session': session }

  call assert_equal(0, luis#do_action('default', candidate, context))
  call assert_equal(1, action_spy.call_count())
  call assert_equal([candidate, context], action_spy.last_args())
  call assert_equal(0, action_spy.last_return_value())
endfunction

function! s:test_do_action__with_undefined_action() abort
  let kind = CreateMockKind()
  let session = luis#session#new(
  \   CreateMockFinder(),
  \   CreateMockSource(),
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   CreateMockHook()
  \ )
  let candidate = { 'word': 'VIM' }
  let context = { 'kind': kind, 'session': session }

  call assert_equal(
  \   "No such action: 'XXX'",
  \   luis#do_action('XXX', candidate, context)
  \ )
endfunction
