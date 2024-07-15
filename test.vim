#!/bin/env -S bash -c '${VIMPROG-vim} -u NONE -i NONE -N -n -X -e -s -S "$0" <(IFS=$\'\n\'; echo "$*")'

function! s:main(root_dir) abort
  set nohidden noswapfile

  let args = filter(getline(1, line('$')), 'v:val != ""')

  silent! %argdelete
  silent! %bwipeout!

  echo matchstr(execute('version'), '^\n*\zs[^\n]\+') "\n"

  let [test_suits, total_tests] = s:load_test_suits(a:root_dir)

  echo 'running' total_tests 'test(s)' "\n"

  let start_time = reltime()
  let result = s:run_test_suits(test_suits, args)
  let end_time = reltime(start_time)

  for error in result.errors
    echo '----' error.script_name . '::' . error.test_name '----'
    for message in error.messages
      echo message "\n"
    endfor
  endfor

  echo 'test result:'
  \    (result.aborted ? 'ABORTED.' : result.failed > 0 ? 'FAILED.' : 'ok.')
  \    result.passed 'passed;'
  \    result.failed 'failed;'
  \    result.ignored 'ignored;'
  \    result.filtered_out 'filtered out;'
  \    'finished in' (substitute(reltimestr(end_time), '^\s*', '', '') . 's')
  \    "\n"

  if result.aborted || result.failed > 0
    cquit!
  else
    qall!
  endif
endfunction

function! s:run_test_suits(test_suits, filters) abort
  let aborted = 0
  let failed = 0
  let passed = 0
  let ignored = 0
  let filtered_out = 0
  let errors = []

  for [script_num, test_suit] in s:shuffle(items(a:test_suits))
    if test_suit.before isnot 0
      call call(test_suit.before, [])
    endif

    for test_function in s:shuffle(test_suit.tests)
      let script_name = fnamemodify(test_suit.script, ':.')
      let test_name = substitute(test_function, '<SNR>\d\+_', '', 'I')
      let full_name = script_name . '::' . test_name

      if max(map(copy(a:filters), 'stridx(full_name, v:val)')) == -1
        let filtered_out += 1
        continue
      endif

      echon full_name ' ... '

      let v:errors = []

      try
        let return_value = call(test_function, [])
      catch
        let return_value = -1
        let message = join(split(v:throwpoint, '\.\.')[1:], "\n")
        \           . "\n"
        \           . v:exception
        call add(errors, {
        \   'script_name': script_name,
        \   'test_name': test_name,
        \   'messages': [message],
        \ })
      endtry

      if len(v:errors) > 0
        let messages = map(
        \   copy(v:errors),
        \   { i, message -> substitute(
        \       join(split(message, '\.\.'), "\n"),
        \       '^\S\+\zs\s\zeline\s\d\+:',
        \       "\n",
        \       ''
        \     )
        \   }
        \ )
        call add(errors, {
        \   'script_name': script_name,
        \   'test_name': test_name,
        \   'messages': messages,
        \ })
      endif

      if type(return_value) == v:t_string
        call add(errors, {
        \   'script_name': script_name,
        \   'test_name': test_name,
        \   'messages': [return_value],
        \ })
        let ignored += 1
        echon 'ignored' "\n"
      elseif return_value == -1 || len(v:errors) > 0
        let failed += 1
        echon 'FAILED' "\n"
      else
        let passed += 1
        echon 'ok' "\n"
      endif

      if len(getbufinfo({ 'buflisted': 1 })) > 1
      \  || line('$') > 1
      \  || col('$') > 1
      \  || winnr('$') > 1
      \  || tabpagenr('$') > 1
        call add(errors, {
        \   'script_name': script_name,
        \   'test_name': test_name,
        \   'messages': [
        \     'CAUTION: Unclean buffers, windows, or tabs were found, therefore the execution of remaining tests has been aborted.'
        \   ],
        \ })
        let aborted = 1
        break
      endif
    endfor

    if test_suit.after isnot 0
      call call(test_suit.after, [])
    endif

    if aborted
      break
    endif
  endfor

  return {
  \   'aborted': aborted,
  \   'failed': failed,
  \   'passed': passed,
  \   'ignored': ignored,
  \   'filtered_out': filtered_out,
  \   'errors': errors,
  \ }
endfunction

function! s:load_test_suits(root_dir) abort
  let &runtimepath .= ',' . a:root_dir
  let &packpath .= ',' . a:root_dir

  for test_file in globpath(a:root_dir, 'test/**/*_test.vim', 0, 1)
    source `=test_file`
  endfor

  let script_paths = {}

  for line in split(execute('0verbose scriptnames'), '\n')
    let matches = matchlist(line, '^\s*\(\d\+\):\s\(.*\)')
    if empty(matches)
      continue
    endif
    let script_num = matches[1]
    let script_path = fnamemodify(matches[2], ':p')
    if stridx(script_path, a:root_dir . '/test/') == 0
      let script_paths[script_num] = script_path
    endif
  endfor

  let raw_funcitons = split(execute('0verbose function'), '\n')
  let test_suits = {}
  let total_tests = 0

  for raw_function in raw_funcitons
    let script_num = matchstr(raw_function, '<SNR>\zs\d\+')
    if !has_key(script_paths, script_num)
      continue
    endif
    if !has_key(test_suits, script_num)
      let test_suits[script_num] = {
      \   'script': script_paths[script_num],
      \   'before': 0,
      \   'after': 0,
      \   'tests': [],
      \ }
    endif
    let function_name = matchstr(raw_function, '<SNR>\d\+_\a\w*\>')
    let test_name = substitute(function_name, '<SNR>\d\+_', '', 'I')
    if test_name ==# 'before'
      let test_suits[script_num].before = function_name
    elseif test_name ==# 'after'
      let test_suits[script_num].after = function_name
    elseif test_name =~# '^test_'
      call add(test_suits[script_num].tests, function_name)
      let total_tests += 1
    endif
  endfor

  return [test_suits, total_tests]
endfunction

function! s:shuffle(elements) abort
  let Rand = exists('*rand') ? function('rand') : { -> reltime()[1] }
  let l = len(a:elements)
  while l > 0
    let i = Rand() % l
    let l -= 1
    let tmp = a:elements[i]
    let a:elements[i] = a:elements[l]
    let a:elements[l] = tmp
  endwhile
  return a:elements
endfunction

verbose call s:main(expand('<sfile>:p:h'))
