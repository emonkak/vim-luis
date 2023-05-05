function! Spy(func_ref) abort
  let spy = copy(s:Spy)
  let spy._func_ref = a:func_ref
  let spy._func_name = get(a:func_ref, 'name')
  let spy._func_def = s:get_func_def(spy._func_name)
  let spy._calls = []
  return spy
endfunction

let s:Spy = {}

function! s:Spy.call(args, ...) abort dict
  if a:0 > 0
    let return_value = call(self._func_ref, a:args, a:1)
    call add(self._calls, {
    \   'args': a:args,
    \   'return_value': return_value,
    \   'self': a:1,
    \ })
  else
    let return_value = call(self._func_ref, a:args)
    call add(self._calls, {
    \   'args': a:args,
    \   'return_value': return_value,
    \ })
  endif
  return return_value
endfunction

function! s:Spy.call_count() abort dict
  return len(self._calls)
endfunction

function! s:Spy.calls() abort dict
  return self._calls
endfunction

function! s:Spy.called() abort dict
  return len(self._calls) > 0
endfunction

function! s:Spy.function() abort dict
  let spy = self
  let wrapper = {}

  function! wrapper.call(...) abort closure
    if self is wrapper
      return spy.call(a:000)
    else
      return spy.call(a:000, self)
    endif
  endfunction

  return wrapper.call
endfunction

function! s:Spy.hijack() abort dict
  let spy = self
  let func_options = s:get_func_options(self._func_def)

  if get(func_options, 'dict')
    let definition = [
    \   'function! ' . self._func_name . '(...) abort closure dict',
    \   '  return spy.call(a:000, self)',
    \   'endfunction',
    \ ]
  else
    let definition = [
    \   'function! ' . self._func_name . '(...) abort closure',
    \   '  return spy.call(a:000)',
    \   'endfunction',
    \ ]
  endif

  execute join(definition, "\n")
endfunction

function! s:Spy.override(callback) abort dict
  let spy = self
  let Callback = a:callback
  let wrapper = {}

  function! wrapper.call(...) abort closure
    let context = self is wrapper
    \           ? { 'args': a:000, 'spy': spy }
    \           : { 'args': a:000, 'spy': spy, 'self': self }
    return Callback(context)
  endfunction

  let self._func_ref = wrapper.call
endfunction

function! s:Spy.restore() abort dict
  if self._func_def != ''
    execute s:normalize_func_def(self._func_def)
  endif
endfunction

function! s:get_func_def(func_name) abort
  if a:func_name =~ '^\%([sg]:\|\%(<SNR>\|' . "\<SNR>" . '\)\d\+_\)\?\h\w*\%(#\h\w*\)*$'
    return execute('0verbose function ' . a:func_name)
  else
    " Unable to get function definition for a lambda or a local dict function.
    return ''
  endif
endfunction

function! s:get_func_options(func_def) abort
  let option_names = split(matchstr(
  \   a:func_def,
  \   '^[\n ]*function \%(\a:\|<SNR>\)\?[0-9A-Za-z#_]\+([^)]*)\zs\%( \w\+\)*'
  \ ), ' ')
  let options = {}
  for option_name in option_names
    let options[option_name] = 1
  endfor
  return options
endfunction

function! s:normalize_func_def(func_def) abort
  let func_def = a:func_def
  " Remove beginning spaces
  let func_def = substitute(func_def, '^[ \n]\+', '', '')
  " Add bang
  let func_def = substitute(func_def, '^function\s', 'function! ', '')
  " Remove line numbers
  let func_def = substitute(func_def, '\%(^\|\n\)\zs[0-9 ]\{1,3}', '', 'g')
  " Remove indents
  let func_def = substitute(
  \    func_def,
  \   '\n\zs\%(│\s\+\)\+',
  \   '\=repeat(" ", strchars(submatch(0)))',
  \   'g'
  \ )
  return func_def
endfunction

function! s:test_call() abort
  let spy = Spy(funcref('s:_greet'))
  call assert_equal('Hello Vim!', spy.call(['Vim']))
  call assert_equal(1, spy.call_count())
  call assert_equal([{ 'args': ['Vim'], 'return_value': 'Hello Vim!' }], spy.calls())

  let F = spy.function()
  call assert_equal('Hello NeoVim!', F('NeoVim'))
  call assert_equal(2, spy.call_count())
  call assert_equal([
  \   { 'args': ['Vim'], 'return_value': 'Hello Vim!' },
  \   { 'args': ['NeoVim'], 'return_value': 'Hello NeoVim!' },
  \ ], spy.calls())
endfunction

function! s:test_call_with_dict() abort
  let spy = Spy(funcref('s:_greet_with_dict'))
  call assert_equal('Hello Vim!', spy.call([], { 'name': 'Vim' }))
  call assert_equal(1, spy.call_count())
  call assert_equal([
  \   { 'args': [], 'return_value': 'Hello Vim!', 'self': { 'name': 'Vim' } },
  \ ], spy.calls())

  let F = spy.function()
  call assert_equal('Hello NeoVim!', call(F, [], { 'name': 'NeoVim' }))
  call assert_equal(2, spy.call_count())
  call assert_equal([
  \   { 'args': [], 'return_value': 'Hello Vim!', 'self': { 'name': 'Vim' } },
  \   { 'args': [], 'return_value': 'Hello NeoVim!', 'self': { 'name': 'NeoVim' } },
  \ ], spy.calls())
endfunction

function! s:test_hijack() abort
  let spy = Spy(funcref('s:_greet'))
  call spy.override({ _ -> 'Hi ' . _.args[0] . '!' })
  call spy.hijack()

  call assert_equal('Hi Vim!', s:_greet('Vim'))
  call assert_equal(1, spy.call_count())
  call assert_equal([{ 'args': ['Vim'], 'return_value': 'Hi Vim!' }], spy.calls())

  call spy.restore()
  call assert_notequal('', spy._func_def)
  call assert_equal(spy._func_def, s:get_func_def('s:_greet'))

  call assert_equal('Hello Vim!', s:_greet('Vim'))
  call assert_equal(1, spy.call_count())
  call assert_equal([{ 'args': ['Vim'], 'return_value': 'Hi Vim!' }], spy.calls())
endfunction

function! s:test_hijack_with_dict() abort
  let spy = Spy(funcref('s:_greet_with_dict'))
  call spy.override({ _ -> 'Hi ' . _.self.name . '!' })
  call spy.hijack()

  call assert_equal('Hi Vim!', call('s:_greet_with_dict', [], { 'name': 'Vim' }))
  call assert_equal(1, spy.call_count())
  call assert_equal([
  \   { 'args': [], 'return_value': 'Hi Vim!', 'self': { 'name': 'Vim' } },
  \ ], spy.calls())

  call spy.restore()
  call assert_notequal('', spy._func_def)
  call assert_equal(spy._func_def, s:get_func_def('s:_greet_with_dict'))

  call assert_equal('Hello Vim!', call('s:_greet_with_dict', [], { 'name': 'Vim' }))
  call assert_equal(1, spy.call_count())
  call assert_equal([
  \   { 'args': [], 'return_value': 'Hi Vim!', 'self': { 'name': 'Vim' } },
  \ ], spy.calls())
endfunction

function! s:_greet(name) abort
  return 'Hello ' . a:name . '!'
endfunction

function! s:_greet_with_dict() abort dict
  return 'Hello ' . self.name . '!'
endfunction
