silent runtime! test/mocks.vim
silent runtime! test/spy.vim

let s:ttyin = has('nvim')
\             || (has('patch-8.0.96')
\                 ? has('ttyin')
\                 : has('unix') && libcallnr('', 'isatty', 0))

function! s:test_guess_candidate__returns_completed_item() abort
  let v:errmsg = ''
  silent! let v:completed_item = {}
  if v:errmsg =~# '^E46:'
    return 'v:completed_item must be writable.'
  endif

  let ui = luis#ui#popupmenu#new({})

  let v:completed_item = {
  \   'word': 'VIM',
  \   'user_data': {},
  \ }
  let candidate = ui.guess_candidate()
  call assert_equal(v:completed_item, candidate)
  call assert_true(v:completed_item isnot candidate)

  " Decode user_data as JSON if it is a string.
  let v:completed_item = {
  \   'word': 'VIM',
  \   'user_data': '{"file_path": "/VIM"}',
  \ }
  let expected_candidate = {
  \   'word': 'VIM',
  \   'user_data': { 'file_path': '/VIM' },
  \ }
  let candidate = ui.guess_candidate()
  call assert_equal(expected_candidate, candidate)
  call assert_true(expected_candidate isnot candidate)

  let v:completed_item = {}
endfunction

function! s:test_guess_candidate__returns_first_candidate() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

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

    let ui._last_candidates = [
    \   { 'word': 'foo', 'user_data': {} },
    \   { 'word': 'bar', 'user_data': {} },
    \   { 'word': 'baz', 'user_data': {} },
    \ ]
    let ui._last_pattern_raw = '>'

    let candidate = ui.guess_candidate()
    call assert_equal(ui._last_candidates[0], candidate)
    call assert_true(ui._last_candidates[0] isnot candidate)

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

function! s:test_guess_candidate__returns_selected_candidate() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

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

    let ui._last_candidates = [
    \   { 'word': 'foo', 'user_data': {} },
    \   { 'word': 'bar', 'user_data': {} },
    \   { 'word': 'baz', 'user_data': {} },
    \ ]
    call setline(line('.'), 'bar')

    let candidate = ui.guess_candidate()
    call assert_equal(ui._last_candidates[1], candidate)
    call assert_true(ui._last_candidates[1] isnot candidate)
    call assert_equal('bar', ui.current_pattern())

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

function! s:test_guess_candidate__returns_no_candidate() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

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

    let ui._last_candidates = []
    let ui._last_pattern_raw = '>VIM'
    call setline(line('.'), '>VIM')

    call assert_equal(0, ui.guess_candidate())
    call assert_equal('VIM', ui.current_pattern())

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
  if !s:ttyin
    return 'TTY is required.'
  endif

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
  if !s:ttyin
    return 'TTY is required.'
  endif

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

  let ui._last_candidates = [
  \   { 'word': 'foo', 'user_data': {} },
  \   { 'word': 'bar', 'user_data': {} },
  \   { 'word': 'baz', 'user_data': {} },
  \ ]

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())
    call assert_equal({
    \   'row': screenrow() + 4,
    \   'col': 1,
    \   'width': 80,
    \   'height': &previewheight,
    \ }, ui.preview_bounds())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
    call assert_equal({
    \   'row': 0,
    \   'col': 0,
    \   'width': 0,
    \   'height': 0,
    \ }, ui.preview_bounds())

    " Reuse the existing luis buffer.
    call ui.start(session)

    call assert_equal('A', s:consume_keys())
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())
    call assert_equal({
    \   'row': screenrow() + 4,
    \   'col': 1,
    \   'width': 80,
    \   'height': &previewheight,
    \ }, ui.preview_bounds())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
    call assert_equal({
    \   'row': 0,
    \   'col': 0,
    \   'width': 0,
    \   'height': 0,
    \ }, ui.preview_bounds())

    " Start after unload the existing luis buffer.
    call ui.start(session)

    call assert_equal('A', s:consume_keys())
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())
    call assert_equal({
    \   'row': screenrow() + 4,
    \   'col': 1,
    \   'width': 80,
    \   'height': &previewheight,
    \ }, ui.preview_bounds())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
    call assert_equal({
    \   'row': 0,
    \   'col': 0,
    \   'width': 0,
    \   'height': 0,
    \ }, ui.preview_bounds())
  finally
    execute ui_bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_start__with_initial_pattern() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

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

  let ui._last_candidates = [
  \   { 'word': 'foo', 'user_data': {} },
  \   { 'word': 'bar', 'user_data': {} },
  \   { 'word': 'baz', 'user_data': {} },
  \ ]

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())
    call assert_equal({
    \   'row': screenrow() + 4,
    \   'col': 1,
    \   'width': 80,
    \   'height': &previewheight,
    \ }, ui.preview_bounds())

    " `last_pattern_raw` is not set, so set it manually.
    let ui._last_pattern_raw = '>VIM'

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
    call assert_equal({
    \   'row': 0,
    \   'col': 0,
    \   'width': 0,
    \   'height': 0,
    \ }, ui.preview_bounds())

    call ui.start(session)

    " Reuse existing luis buffer.
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(ui.is_active())
    call assert_equal({
    \   'row': screenrow() + 4,
    \   'col': 1,
    \   'width': 80,
    \   'height': &previewheight,
    \ }, ui.preview_bounds())

    call ui.quit()

    call assert_notequal('luis-popupmenu-ui', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(ui.is_active())
    call assert_equal({
    \   'row': 0,
    \   'col': 0,
    \   'width': 0,
    \   'height': 0,
    \ }, ui.preview_bounds())
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
