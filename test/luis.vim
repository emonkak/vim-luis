runtime! test/spy.vim

function! s:test_acc_text() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let source.is_valid_for_acc = { candidate ->
  \   get(candidate.user_data, 'valid_for_acc', 1)
  \ }

  let cs1 = [
  \   { 'word': 'usr/share/man/man1', 'user_data': {} },
  \ ]
  let cs2 = [
  \   { 'word': 'usr/share/w y 1', 'user_data': {} },
  \   { 'word': 'usr/share/ x z2', 'user_data': {} },
  \   { 'word': 'usr/share/w y 3', 'user_data': {} },
  \   { 'word': 'usr/share/ x z4', 'user_data': {} },
  \ ]
  let cs3 = [
  \   { 'word': 'bin/1/1', 'user_data': {} },
  \   { 'word': 'etc/2/2', 'user_data': {} },
  \   { 'word': 'usr/3/3', 'user_data': {} },
  \   { 'word': 'var/4/4', 'user_data': {} },
  \ ]
  let cs4 = [
  \   { 'word': '1/X', 'user_data': { 'valid_for_acc': 0 } },
  \   { 'word': '2/X', 'user_data': { 'valid_for_acc': 0 } },
  \   { 'word': '3/X', 'user_data': {} },
  \   { 'word': '4/X', 'user_data': { 'valid_for_acc': 0 } },
  \ ]

  " len(components) == 2
  call assert_equal('usr', luis#_acc_text('/', cs1, source))
  call assert_equal('usr', luis#_acc_text('u/', cs1, source))
  call assert_equal('usr', luis#_acc_text('s/', cs1, source))
  call assert_equal('usr/share', luis#_acc_text('sh/', cs1, source))
  call assert_equal('usr/share/man', luis#_acc_text('m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#_acc_text('1/', cs1, source))

  call assert_equal('usr/share/w y 1', luis#_acc_text('w/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#_acc_text('x/', cs2, source))
  call assert_equal('usr/share/w y 1', luis#_acc_text('y/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#_acc_text('z/', cs2, source))

  call assert_equal('bin', luis#_acc_text('b/', cs3, source))
  call assert_equal('etc', luis#_acc_text('e/', cs3, source))
  call assert_equal('usr', luis#_acc_text('r/', cs3, source))
  call assert_equal('usr', luis#_acc_text('u/', cs3, source))
  call assert_equal('var', luis#_acc_text('v/', cs3, source))

  call assert_equal('3/X', luis#_acc_text('X/', cs4, source))

  " len(components) >= 3
  call assert_equal('usr/share', luis#_acc_text('usr//', cs1, source))
  call assert_equal('usr/share', luis#_acc_text('usr/s/', cs1, source))
  call assert_equal('usr/share', luis#_acc_text('usr/sh/', cs1, source))
  call assert_equal('usr/share/man', luis#_acc_text('usr/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#_acc_text('usr/1/', cs1, source))
  call assert_equal('usr/share', luis#_acc_text('usr/share/', cs1, source))

  call assert_equal('usr/share/man', luis#_acc_text('usr/share//', cs1, source))
  call assert_equal('usr/share/man', luis#_acc_text('usr/share/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#_acc_text('usr/share/1/', cs1, source))

  call assert_equal('etc/2', luis#_acc_text('etc//', cs3, source))
  call assert_equal('var/4', luis#_acc_text('var//', cs3, source))

  " No components
  let v:errmsg = ''
  silent! call luis#_acc_text('', [], source)
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  let v:errmsg = ''
  silent! call assert_equal('', luis#_acc_text('', cs1, source))
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  " No proper candidate for a:pattern
  call assert_equal('', luis#_acc_text('x/', [], source))
  call assert_equal('', luis#_acc_text('x/', cs1, source))
  call assert_equal('', luis#_acc_text('2/', cs1, source))
  call assert_equal('', luis#_acc_text('u/s/m/', cs1, source))
  call assert_equal('', luis#_acc_text('USR//', cs1, source))
endfunction

function! s:test_do_action() abort
  let default_action_spy = Spy({ candidate, context -> 0 })

  let kind = s:create_mock_kind()
  let kind.action_table.default  = default_action_spy.to_funcref()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())

    let candidate = { 'word': 'VIM' }
    let context = { 'kind': kind, 'session': session }

    call assert_equal(0, luis#do_action(kind, 'default', candidate))
    call assert_equal(1, default_action_spy.call_count())
    call assert_equal([candidate, context], default_action_spy.last_args())
    call assert_equal(0, default_action_spy.last_return_value())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_do_action__action_is_not_definied() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())

    let candidate = { 'word': 'VIM' }
    let context = { 'session': session }

    call assert_equal(
    \   "luis: Action 'XXX' is not defined",
    \   luis#do_action(kind, 'XXX', candidate)
    \ )
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_quit() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let [hook, hook_spies] = SpyDict(s:create_mock_hook())
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    call assert_equal(1, luis#start(session, { 'hook': hook }))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())

    call assert_equal(1, luis#quit())
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.quit.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(1, hook_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_leave.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_leave.last_self())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(1, source_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_leave.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_leave.last_self())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_quit__session_is_not_active() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let [hook, hook_spies] = SpyDict(s:create_mock_hook())
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 0 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    silent call assert_equal(0, luis#quit())
    call assert_equal(0, session_spies.quit.call_count())

    call assert_equal(1, luis#start(session, { 'hook': hook }))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())

    silent call assert_equal(0, luis#quit())
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(0, session_spies.quit.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_restart() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let [hook, hook_spies] = SpyDict(s:create_mock_hook())
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 0 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    call assert_equal(1, luis#start(session, { 'hook': hook }))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())

    call assert_equal(1, luis#restart())
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(2, session_spies.start.call_count())
    call assert_equal(2, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(2, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_restart__session_is_already_active() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let [hook, hook_spies] = SpyDict(s:create_mock_hook())
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    call assert_equal(1, luis#start(session, { 'hook': hook }))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())

    silent call assert_equal(0, luis#restart())
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_restart__session_is_not_started_yet() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let [hook, hook_spies] = SpyDict(s:create_mock_hook())
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    silent call assert_equal(0, luis#restart())
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(0, session_spies.start.call_count())
    call assert_equal(0, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(0, source_spies.on_source_enter.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_start() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let [hook, hook_spies] = SpyDict(s:create_mock_hook())
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 0 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    call assert_equal(1, luis#start(session, { 'hook': hook }))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())

    call assert_equal(1, luis#start(session, { 'hook': hook }))
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(2, session_spies.start.call_count())
    call assert_equal(2, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(2, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_start__session_is_already_active() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let [hook, hook_spies] = SpyDict(s:create_mock_hook())
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    call assert_equal(1, luis#start(session, { 'hook': hook }))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())

    " Fail while the session is already active.
    silent call assert_equal(0, luis#start(session, { 'hook': hook }))
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_start__session_is_invalid() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let [hook, hook_spies] = SpyDict(s:create_mock_hook())
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    let v:errmsg = ''
    silent! call luis#start({}, { 'hook': hook })
    call assert_match('luis: Invalid session:', v:errmsg)
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(0, session_spies.start.call_count())
    call assert_equal(0, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
    call assert_equal(0, source_spies.on_source_enter.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_take_action__choose_action() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let candidate = { 'word': 'VIM', 'user_data': {} }
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> candidate },
  \   'reload_candidates': { -> {} },
  \ })

  let default_action_spy = Spy({ candidate, context -> 0 })
  let kind = session.source.default_kind
  let kind.action_table.default
  \   = default_action_spy.to_funcref()

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(1, session_spies.start.call_count())

    call feedkeys("\<CR>", 'nt')
    silent call assert_equal(1, luis#take_action())
    call assert_equal(0, getchar(0))

    let context = { 'kind': kind, 'session': session }

    call assert_equal(1, session_spies.quit.call_count())
    call assert_equal(1, source_spies.on_action.call_count())
    call assert_equal([candidate, context], source_spies.on_action.last_args())
    call assert_equal(1, source_spies.on_source_leave.call_count())
    call assert_equal(1, default_action_spy.call_count())
    call assert_equal([candidate, context], default_action_spy.last_args())
    call assert_equal(0, default_action_spy.last_return_value())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_take_action__do_default_action() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let [source, source_spies] = SpyDict(s:create_mock_source(kind, matcher))
  let candidate = { 'word': 'VIM', 'user_data': {} }
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> candidate },
  \   'reload_candidates': { -> {} },
  \ })

  let default_action_spy = Spy({ candidate, context -> 0 })
  let kind = session.source.default_kind
  let kind.action_table.default
  \   = default_action_spy.to_funcref()

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())

    silent call assert_equal(1, luis#take_action('default'))

    let context = { 'kind': kind, 'session': session }

    call assert_equal(1, session_spies.quit.call_count())
    call assert_equal(1, source_spies.on_action.call_count())
    call assert_equal([candidate, context], source_spies.on_action.last_args())
    call assert_equal(1, source_spies.on_source_leave.call_count())
    call assert_equal(1, default_action_spy.call_count())
    call assert_equal([candidate, context], default_action_spy.last_args())
    call assert_equal(0, default_action_spy.last_return_value())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_take_action__session_is_not_active() abort
  let kind = s:create_mock_kind()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 0 },
  \   'guess_candidate': { -> {} },
  \   'reload_candidates': { -> {} },
  \ })

  try
    silent call assert_equal(0, luis#take_action('default'))

    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())

    silent call assert_equal(0, luis#take_action('default'))
    call assert_equal(1, session_spies.is_active.call_count())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:test_take_action__with_kind() abort
  let default_action_spy = Spy({ candidate, context -> 0 })

  let kind = s:create_mock_kind()
  let kind.action_table.default  = default_action_spy.to_funcref()
  let matcher = s:create_mock_matcher()
  let source = s:create_mock_source(kind, matcher)
  let candidate = { 'word': 'VIM', 'user_data': { 'kind': kind } }
  let [session, session_spies] = SpyDict({
  \   'source': source,
  \   'start': { -> 0 },
  \   'quit': { -> 0 },
  \   'is_active': { -> 1 },
  \   'guess_candidate': { -> candidate },
  \   'reload_candidates': { -> {} },
  \ })

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(1, session_spies.start.call_count())

    silent call assert_equal(1, luis#take_action('default'))

    let context = { 'kind': kind, 'session': session }

    call assert_equal(1, default_action_spy.call_count())
    call assert_equal([candidate, context], default_action_spy.last_args())
    call assert_equal(0, default_action_spy.last_return_value())
  finally
    call luis#_reset_session()
  endtry
endfunction

function! s:create_mock_kind() abort
  return {
  \   'name': 'mock_kind',
  \   'action_table': {
  \     'default': { candidate, context -> 0 },
  \   },
  \   'key_table': {
  \     "\<CR>": 'default',
  \   },
  \ }
endfunction

function! s:create_mock_matcher() abort
  return {
  \   'filter_candidates': { candidates, context -> candidates },
  \   'normalize_candidate': { candidate, index, context -> candidate },
  \   'sort_candidates': { candidates, context -> candidates },
  \ }
endfunction

function! s:create_mock_source(default_kind, matcher) abort
  return {
  \   'default_kind': a:default_kind,
  \   'gather_candidates': { context -> [] },
  \   'is_valid_for_acc': { context -> 1 },
  \   'matcher': a:matcher,
  \   'name': 'mock_source',
  \   'on_action': { candidate, context -> 0 },
  \   'on_source_enter': { context -> 0 },
  \   'on_source_leave': { context -> 0 },
  \ }
endfunction

function! s:create_mock_hook() abort
  return {
  \   'on_source_enter': { context -> 0 },
  \   'on_source_leave': { context -> 0 },
  \ }
endfunction
