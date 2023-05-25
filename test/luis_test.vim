silent runtime! test/spy.vim
silent runtime! test/mocks.vim

function! s:test_do_action() abort
  let default_action_spy = Spy({ candidate, context -> 0 })

  let kind = CreateMockKind()
  let kind.action_table.default  = default_action_spy.to_funcref()
  let source = CreateMockSource({ 'default_kind': kind })
  let [session, session_spies] = SpyDict(CreateMockSession(source, {}, {}, 1))

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
    call luis#_clear_session()
  endtry
endfunction

function! s:test_do_action__action_is_not_definied() abort
  let source = CreateMockSource()
  let [session, session_spies] = SpyDict(CreateMockSession(source, {}, {}, 1))

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())

    let candidate = { 'word': 'VIM' }
    let context = { 'session': session }

    call assert_equal(
    \   "luis: Action 'XXX' is not defined",
    \   luis#do_action(source.default_kind, 'XXX', candidate)
    \ )
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_quit() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 1))

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())

    call assert_equal(1, luis#quit())
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.quit.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(1, source_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_leave.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_leave.last_self())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(1, hook_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_leave.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_leave.last_self())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_quit__session_is_not_active() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 0))

  try
    silent call assert_equal(0, luis#quit())
    call assert_equal(0, session_spies.quit.call_count())

    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())

    silent call assert_equal(0, luis#quit())
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(0, session_spies.quit.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_restart() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 0))

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())

    call assert_equal(1, luis#restart())
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(2, session_spies.start.call_count())
    call assert_equal(2, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(2, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_restart__session_is_already_active() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 1))

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())

    silent call assert_equal(0, luis#restart())
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_restart__session_is_not_started_yet() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 1))

  try
    silent call assert_equal(0, luis#restart())
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(0, session_spies.start.call_count())
    call assert_equal(0, source_spies.on_source_enter.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(0, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_start() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 0))

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())

    call assert_equal(1, luis#start(session))
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(2, session_spies.start.call_count())
    call assert_equal(2, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(2, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_start__session_is_already_active() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 1))

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_enter.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_enter.last_self())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_enter.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_enter.last_self())
    call assert_equal(0, hook_spies.on_source_leave.call_count())

    " Fail while the session is already active.
    silent call assert_equal(0, luis#start(session))
    call assert_equal(1, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(1, source_spies.on_source_enter.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())
    call assert_equal(1, hook_spies.on_source_enter.call_count())
    call assert_equal(0, hook_spies.on_source_leave.call_count())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_start__session_is_invalid() abort
  let v:errmsg = ''
  silent! call luis#start({})
  call assert_match('luis: Invalid Session:', v:errmsg)
endfunction

function! s:test_take_action__choose_action() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let candidate = { 'word': 'VIM', 'user_data': {} }
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))

  let default_action_spy = Spy({ candidate, context -> 0 })
  let kind = session.source.default_kind
  let kind.action_table.default = default_action_spy.to_funcref()

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
    call assert_equal(source, source_spies.on_action.last_self())
    call assert_equal(1, source_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_leave.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_leave.last_self())

    call assert_equal(1, hook_spies.on_action.call_count())
    call assert_equal([candidate, context], hook_spies.on_action.last_args())
    call assert_equal(hook, hook_spies.on_action.last_self())
    call assert_equal(1, hook_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_leave.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_leave.last_self())

    call assert_equal(1, default_action_spy.call_count())
    call assert_equal([candidate, context], default_action_spy.last_args())
    call assert_equal(0, default_action_spy.last_return_value())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_take_action__do_default_action() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let candidate = { 'word': 'VIM', 'user_data': {} }
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))

  let default_action_spy = Spy({ candidate, context -> 0 })
  let kind = session.source.default_kind
  let kind.action_table.default = default_action_spy.to_funcref()

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(1, session_spies.start.call_count())
    call assert_equal(0, source_spies.on_source_leave.call_count())

    silent call assert_equal(1, luis#take_action('default'))

    let context = { 'kind': kind, 'session': session }

    call assert_equal(1, session_spies.quit.call_count())

    call assert_equal(1, source_spies.on_action.call_count())
    call assert_equal([candidate, context], source_spies.on_action.last_args())
    call assert_equal(source, source_spies.on_action.last_self())
    call assert_equal(1, source_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   source_spies.on_source_leave.last_args()
    \ )
    call assert_equal(source, source_spies.on_source_leave.last_self())

    call assert_equal(1, hook_spies.on_action.call_count())
    call assert_equal([candidate, context], hook_spies.on_action.last_args())
    call assert_equal(hook, hook_spies.on_action.last_self())
    call assert_equal(1, hook_spies.on_source_leave.call_count())
    call assert_equal(
    \   [{ 'session': session }],
    \   hook_spies.on_source_leave.last_args()
    \ )
    call assert_equal(hook, hook_spies.on_source_leave.last_self())

    call assert_equal(1, default_action_spy.call_count())
    call assert_equal([candidate, context], default_action_spy.last_args())
    call assert_equal(0, default_action_spy.last_return_value())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_take_action__session_is_not_active() abort
  let source = CreateMockSource()
  let [session, session_spies] = SpyDict(CreateMockSession(source, {}, {}, 0))

  try
    silent call assert_equal(0, luis#take_action('default'))

    call assert_equal(1, luis#start(session))
    call assert_equal(0, session_spies.is_active.call_count())
    call assert_equal(1, session_spies.start.call_count())

    silent call assert_equal(0, luis#take_action('default'))
    call assert_equal(1, session_spies.is_active.call_count())
  finally
    call luis#_clear_session()
  endtry
endfunction

function! s:test_take_action__with_kind() abort
  let default_action_spy = Spy({ candidate, context -> 0 })

  let kind = CreateMockKind()
  let kind.action_table.default  = default_action_spy.to_funcref()
  let source = CreateMockSource({ 'default_kind': kind })
  let candidate = { 'word': 'VIM', 'user_data': { 'kind': kind } }
  let [session, session_spies] = SpyDict(CreateMockSession(source, {}, candidate, 1))

  try
    call assert_equal(1, luis#start(session))
    call assert_equal(1, session_spies.start.call_count())

    silent call assert_equal(1, luis#take_action('default'))

    let context = { 'kind': kind, 'session': session }

    call assert_equal(1, default_action_spy.call_count())
    call assert_equal([candidate, context], default_action_spy.last_args())
    call assert_equal(0, default_action_spy.last_return_value())
  finally
    call luis#_clear_session()
  endtry
endfunction
