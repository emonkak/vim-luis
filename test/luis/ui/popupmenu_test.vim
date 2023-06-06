silent runtime! test/mocks.vim
silent runtime! test/spy.vim

function! s:test_guess_candidate__from_completed_item() abort
  let ui = luis#ui#popupmenu#new({})

  try
    let candidate = {
    \   'word': 'VIM',
    \   'user_data': {},
    \ }
    let v:completed_item = copy(candidate)
    call assert_equal(candidate, ui.guess_candidate())

    " Decode user_data as JSON if it is a string.
    let v:completed_item = { 'word': 'VIM', 'user_data': '{"file_path": "/VIM"}' }
    call assert_equal({
    \   'word': 'VIM',
    \   'user_data': { 'file_path': '/VIM' },
    \ }, ui.guess_candidate())
  catch 'Vim(let):E46:'
    return 'v:completed_item must be writable.'
  endtry

  let v:completed_item = {}
endfunction

function! s:test_guess_candidate__from_first_candidate() abort
  let ui = luis#ui#popupmenu#new({})
  let session = {
  \   'id': 1,
  \   'source': CreateMockSource(),
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \   'initial_pattern': '',
  \ }

  call assert_false(ui.is_active())

  let original_bufnr = bufnr('%')
  call ui.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())

    let ui.last_candidates = [
    \   { 'word': 'foo', 'user_data': {} },
    \   { 'word': 'bar', 'user_data': {} },
    \   { 'word': 'baz', 'user_data': {} },
    \ ]
    let ui.last_pattern_raw = '>'

    call assert_equal(ui.last_candidates[0], ui.guess_candidate())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_guess_candidate__from_selected_candidate() abort
  let ui = luis#ui#popupmenu#new({})
  let session = {
  \   'id': 1,
  \   'source': CreateMockSource(),
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \   'initial_pattern': '',
  \ }

  call assert_false(ui.is_active())

  let original_bufnr = bufnr('%')
  call ui.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())

    let ui.last_candidates = [
    \   { 'word': 'foo', 'user_data': {} },
    \   { 'word': 'bar', 'user_data': {} },
    \   { 'word': 'baz', 'user_data': {} },
    \ ]
    call setline(line('.'), 'bar')

    call assert_equal(ui.last_candidates[1], ui.guess_candidate())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_guess_candidate__from_default_candidate() abort
  let ui = luis#ui#popupmenu#new({})
  let session = {
  \   'id': 1,
  \   'source': CreateMockSource(),
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \   'initial_pattern': '',
  \ }

  call assert_false(ui.is_active())

  let original_bufnr = bufnr('%')
  call ui.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())

    let ui.last_candidates = []
    let ui.last_pattern_raw = '>VIM'
    call setline(line('.'), '>VIM')

    call assert_equal({ 'word': 'VIM', 'user_data': {} }, ui.guess_candidate())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_refresh_candidates() abort
  let [ui, ui_spies] = SpyDict(luis#ui#popupmenu#new({}))
  let session = {
  \   'id': 1,
  \   'source': CreateMockSource(),
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \   'initial_pattern': '',
  \ }

  call assert_false(ui.is_active())

  let original_bufnr = bufnr('%')
  call ui.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())

    function! s:on_CompleteDone() abort closure
      call ui.refresh_candidates()
      call assert_equal("\<C-x>", nr2char(getchar(0)))
      call assert_equal("\<C-o>", nr2char(getchar(0)))
    endfunction

    autocmd! CompleteDone <buffer>  call s:on_CompleteDone()

    normal! A

    call assert_equal(1, ui_spies.refresh_candidates.call_count())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_start__without_initial_pattern() abort
  let ui = luis#ui#popupmenu#new()
  let session = {
  \   'id': 1,
  \   'source': CreateMockSource(),
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \   'initial_pattern': '',
  \ }

  call assert_false(ui.is_active())

  let original_bufnr = bufnr('%')
  call ui.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())

    " Reuse the existing luis buffer.
    call ui.start(session)

    call assert_equal('A', s:consume_keys())
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())

    " Start after unload the existing luis buffer.
    call ui.start(session)

    call assert_equal('A', s:consume_keys())
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_start__with_initial_pattern() abort
  let ui = luis#ui#popupmenu#new()
  let session = {
  \   'id': 1,
  \   'source': CreateMockSource(),
  \   'ui': ui,
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \   'initial_pattern': 'VIM',
  \ }

  call assert_false(ui.is_active())

  let original_bufnr = bufnr('%')
  call ui.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())

    " `last_pattern_raw` is not set, so set it manually.
    let ui.last_pattern_raw = '>VIM'

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())

    call ui.start(session)

    " Reuse existing luis buffer.
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:consume_keys() abort
  let keys = ''
  while 1
    let char = getchar(0)
    if char is 0
      break
    endif
    let keys .= nr2char(char)
  endwhile
  return keys
endfunction
