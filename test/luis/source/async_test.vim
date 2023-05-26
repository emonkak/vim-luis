silent runtime! test/spy.vim

function! s:test_gather_candidates() abort
  if !has('patch-8.0.0018')
    " When using ":sleep", channel input is not handled.
    return 'patch-8.0.0018 is required.'
  endif

  let spy = Spy({ -> 0 })
  let session = {
  \   'reload_candidates': spy.to_funcref(),
  \ }

  try
    let kind = luis#kind#file#import()
    let command = [
    \   'test/data/filter.sh',
    \   'bash',
    \   '-c',
    \   'for n in {001..100}; do echo $n; done'
    \ ]
    let source = luis#source#async#new('files', kind, command)

    call source.on_source_enter({ 'session': session })

    let candidates = source.gather_candidates({ 'pattern': '00' })

    call assert_equal(candidates, [])

    for i in range(1, 10)
      execute 'sleep' (float2nr(pow(i, 2)) . 'm')
      if spy.called()
        break
      endif
    endfor

    call assert_equal(1, spy.call_count())
    call assert_equal(session, spy.last_self())

    let candidates = source.gather_candidates(({ 'pattern': '00' }))
    call assert_equal([
    \   { 'word': '001' },
    \   { 'word': '002' },
    \   { 'word': '003' },
    \   { 'word': '004' },
    \   { 'word': '005' },
    \   { 'word': '006' },
    \   { 'word': '007' },
    \   { 'word': '008' },
    \   { 'word': '009' },
    \   { 'word': '100' },
    \ ], candidates)

    call source.on_source_leave({})
  finally
    silent runtime! autoload/luis.vim
  endtry
endfunction

function! s:test_gather_candidates__to_candidate() abort
  if !has('patch-8.0.0018')
    return 'patch-8.0.0018 is required.'
  endif

  let spy = Spy({ -> 0 })
  let session = {
  \   'reload_candidates': spy.to_funcref(),
  \ }

  try
    let kind = luis#kind#file#import()
    let command = [
    \   'test/data/filter.sh',
    \   'bash',
    \   '-c',
    \   'for s in {00..10}" "{A..C}; do echo $s; done',
    \ ]
    let options = {
    \   'to_candidate': { line -> { 'word': line[0:1], 'kind': line[3] } },
    \ }
    let source = luis#source#async#new(
    \   'files',
    \   kind,
    \   command,
    \   options
    \ )

    call source.on_source_enter({ 'session': session })

    let candidates = source.gather_candidates({ 'pattern': '1' })

    call assert_equal(candidates, [])

    for i in range(1, 10)
      execute 'sleep' (float2nr(pow(i, 2)) . 'm')
      if spy.called()
        break
      endif
    endfor

    call assert_equal(1, spy.call_count())
    call assert_equal(session, spy.last_self())

    let candidates = source.gather_candidates(({ 'pattern': '1' }))
    call assert_equal([
    \   { 'word': '01', 'kind': 'A' },
    \   { 'word': '01', 'kind': 'B' },
    \   { 'word': '01', 'kind': 'C' },
    \   { 'word': '10', 'kind': 'A' },
    \   { 'word': '10', 'kind': 'B' },
    \   { 'word': '10', 'kind': 'C' },
    \ ], candidates)

    call source.on_source_leave({})
  finally
    silent runtime! autoload/luis.vim
  endtry
endfunction

function! s:test_gather_candidates__debounce_time() abort
  if !has('patch-8.0.0018')
    return 'patch-8.0.0018 is required.'
  endif

  let spy = Spy({ -> 0 })
  let session = {
  \   'reload_candidates': spy.to_funcref(),
  \ }

  try
    let kind = luis#kind#file#import()
    let command = [
    \   'test/data/filter.sh',
    \   'bash',
    \   '-c',
    \   'for n in {001..100}; do echo $n; done'
    \ ]
    let options = {
    \   'debounce_time': 10,
    \ }
    let source = luis#source#async#new(
    \   'files',
    \   kind,
    \   command,
    \   options
    \ )

    call source.on_source_enter({ 'session': session })

    let candidates = source.gather_candidates({ 'pattern': '00' })

    call assert_equal(candidates, [])

    for i in range(1, 10)
      execute 'sleep' (float2nr(pow(i, 2)) . 'm')
      if spy.called()
        break
      endif
    endfor

    call assert_equal(1, spy.call_count())
    call assert_equal(session, spy.last_self())

    let candidates = source.gather_candidates({ 'pattern': '00' })
    call assert_equal([
    \   { 'word': '001' },
    \   { 'word': '002' },
    \   { 'word': '003' },
    \   { 'word': '004' },
    \   { 'word': '005' },
    \   { 'word': '006' },
    \   { 'word': '007' },
    \   { 'word': '008' },
    \   { 'word': '009' },
    \   { 'word': '100' },
    \ ], candidates)

    call source.on_source_leave({})
  finally
    silent runtime! autoload/luis.vim
  endtry
endfunction

function! s:test_source_definition() abort
  let kind = luis#kind#file#import()
  let command = [
  \   'test/data/filter.sh',
  \   'bash',
  \    '-c',
  \    'for n in {0..100}; do echo $n; done'
  \ ]
  let source = luis#source#async#new('files', kind, command)
  call assert_equal(1, luis#validations#validate_source(source))
  call assert_equal('async/files', source.name)
endfunction