function! s:test_gather_candidates() abort
  if !has('patch-8.0.0018')
    " When using ":sleep", channel input is not handled.
    return 'patch-8.0.0018 is required.'
  endif

  let spy = Spy({ -> 0 })

  function! luis#update_candidates() abort closure
    call spy.call([])
  endfunction

  try
    let command = [
    \   'test/data/filter.sh',
    \   'bash',
    \   '-c',
    \   "for n in {001..100}; do echo $n; done"
    \ ]
    let source = luis#source#async#new('files', g:luis#kind#file#export, command)

    call source.on_source_enter()

    let context = { 'pattern': '00' }
    let candidates = source.gather_candidates(context)

    call assert_equal(candidates, [])

    for i in range(1, 10)
      execute 'sleep' (float2nr(pow(i, 2)) . 'm')
      if spy.called()
        break
      endif
    endfor

    call assert_equal([{ 'args': [], 'return_value': 0 }], spy.calls())

    let candidates = source.gather_candidates(context)
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

    call source.on_source_leave()
  finally
    silent runtime! autoload/luis.vim
  endtry
endfunction

function! s:test_gather_candidates__to_candidate() abort
  if !has('patch-8.0.0018')
    return 'patch-8.0.0018 is required.'
  endif

  let spy = Spy({ -> 0 })

  function! luis#update_candidates() abort closure
    call spy.call([])
  endfunction

  try
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
    \   g:luis#kind#file#export,
    \   command,
    \   options
    \ )

    call source.on_source_enter()

    let context = { 'pattern': '1' }
    let candidates = source.gather_candidates(context)

    call assert_equal(candidates, [])

    for i in range(1, 10)
      execute 'sleep' (float2nr(pow(i, 2)) . 'm')
      if spy.called()
        break
      endif
    endfor

    call assert_equal([{ 'args': [], 'return_value': 0 }], spy.calls())

    let candidates = source.gather_candidates(context)
    call assert_equal([
    \   { 'word': '01', 'kind': 'A' },
    \   { 'word': '01', 'kind': 'B' },
    \   { 'word': '01', 'kind': 'C' },
    \   { 'word': '10', 'kind': 'A' },
    \   { 'word': '10', 'kind': 'B' },
    \   { 'word': '10', 'kind': 'C' },
    \ ], candidates)

    call source.on_source_leave()
  finally
    silent runtime! autoload/luis.vim
  endtry
endfunction

function! s:test_gather_candidates__debounce_time() abort
  if !has('patch-8.0.0018')
    return 'patch-8.0.0018 is required.'
  endif

  let spy = Spy({ -> 0 })

  function! luis#update_candidates() abort closure
    call spy.call([])
  endfunction

  try
    let command = [
    \   'test/data/filter.sh',
    \   'bash',
    \   '-c',
    \   "for n in {001..100}; do echo $n; done"
    \ ]
    let options = {
    \   'debounce_time': 10,
    \ }
    let source = luis#source#async#new(
    \   'files',
    \   g:luis#kind#file#export,
    \   command,
    \   options
    \ )

    call source.on_source_enter()

    let context = { 'pattern': '00' }
    let candidates = source.gather_candidates(context)

    call assert_equal(candidates, [])

    for i in range(1, 10)
      execute 'sleep' (float2nr(pow(i, 2)) . 'm')
      if spy.called()
        break
      endif
    endfor

    call assert_equal([{ 'args': [], 'return_value': 0 }], spy.calls())

    let candidates = source.gather_candidates(context)
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

    call source.on_source_leave()
  finally
    silent runtime! autoload/luis.vim
  endtry
endfunction

function s:test_source_definition() abort
  let command = ['test/data/filter.sh', 'bash', '-c', "for n in {0..100}; do echo $n; done"]
  let source = luis#source#async#new('files', g:luis#kind#file#export, command)
  let errors = luis#internal#validate_source(source)
  call assert_equal([], errors)
  call assert_equal('async/files', source.name)
endfunction
