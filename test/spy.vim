if exists('g:loaded_spy')
  finish
endif

function! Spy(funcref) abort
  let spy = copy(s:Spy)
  let spy._funcref = a:funcref
  let spy._calls = []
  return spy
endfunction

function! SpyDict(target) abort
  let target = {}
  let spies = {}

  for [key, Value] in items(a:target)
    if type(Value) is v:t_func
      let spy = Spy(Value)
      let spies[key] = spy
      let target[key] = spy.to_funcref()
    else
      let target[key] = Value
    endif
  endfor

  return [target, spies]
endfunction

let s:Spy = {}

function! s:Spy.args() abort dict
  return map(copy(self._calls), { _, call -> call.args })
endfunction

function! s:Spy.call(args, ...) abort dict
  if a:0 > 0
    let return_value = call(self._funcref, a:args, a:1)
    call add(self._calls, {
    \   'args': a:args,
    \   'return_value': return_value,
    \   'self': a:1,
    \ })
  else
    let return_value = call(self._funcref, a:args)
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

function! s:Spy.called() abort dict
  return len(self._calls) > 0
endfunction

function! s:Spy.last_args() abort dict
  return len(self._calls) > 0 ? self._calls[-1].args : 0
endfunction

function! s:Spy.last_return_value() abort dict
  return len(self._calls) > 0 ? self._calls[-1].return_value : 0
endfunction

function! s:Spy.last_self() abort dict
  return len(self._calls) > 0 ? self._calls[-1].self : v:none
endfunction

function! s:Spy.return_values() abort dict
  return map(copy(self._calls), { _, call -> call.return_value })
endfunction

function! s:Spy.selves() abort dict
  return map(copy(self._calls), { _, call -> call.self })
endfunction

function! s:Spy.to_funcref() abort dict
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

function! s:test_Spy() abort
  let spy = Spy({ name -> 'Hello ' . name . '!' })
  call assert_false(spy.called())
  call assert_equal(0, spy.call_count())
  call assert_equal([], spy.args())
  call assert_equal(0, spy.last_args())
  call assert_equal([], spy.return_values())
  call assert_equal(0, spy.last_return_value())

  call assert_equal('Hello Vim!', spy.call(['Vim']))
  call assert_true(spy.called())
  call assert_equal(1, spy.call_count())
  call assert_equal([['Vim']], spy.args())
  call assert_equal(['Vim'], spy.last_args())
  call assert_equal(['Hello Vim!'], spy.return_values())
  call assert_equal('Hello Vim!', spy.last_return_value())

  let F = spy.to_funcref()
  call assert_equal('Hello NeoVim!', F('NeoVim'))
  call assert_true(spy.called())
  call assert_equal(2, spy.call_count())
  call assert_equal([['Vim'], ['NeoVim']], spy.args())
  call assert_equal(['NeoVim'], spy.last_args())
  call assert_equal(['Hello Vim!', 'Hello NeoVim!'], spy.return_values())
  call assert_equal('Hello NeoVim!', spy.last_return_value())
endfunction

function! s:test_Spy__with_dict() abort
  let _ = {}

  function! _.call() abort dict
    return 'Hello ' . self.name . '!'
  endfunction

  let spy = Spy(_.call)
  call assert_false(spy.called())
  call assert_equal(0, spy.call_count())
  call assert_equal([], spy.args())
  call assert_equal(0, spy.last_args())
  call assert_equal([], spy.return_values())
  call assert_equal(0, spy.last_return_value())

  let self1 = { 'name': 'Vim' }
  call assert_equal('Hello Vim!', spy.call([], self1))
  call assert_true(spy.called())
  call assert_equal(1, spy.call_count())
  call assert_equal([[]], spy.args())
  call assert_equal([], spy.last_args())
  call assert_equal(['Hello Vim!'], spy.return_values())
  call assert_equal('Hello Vim!', spy.last_return_value())
  call assert_equal([self1], spy.selves())
  call assert_equal(self1, spy.last_self())

  let F = spy.to_funcref()
  let self2 = { 'name': 'NeoVim' }
  call assert_equal('Hello NeoVim!', call(F, [], self2))
  call assert_true(spy.called())
  call assert_equal(2, spy.call_count())
  call assert_equal([[], []], spy.args())
  call assert_equal([], spy.last_args())
  call assert_equal(['Hello Vim!', 'Hello NeoVim!'], spy.return_values())
  call assert_equal('Hello NeoVim!', spy.last_return_value())
  call assert_equal([self1, self2], spy.selves())
  call assert_equal(self2, spy.last_self())
endfunction

function! s:test_SpyDict() abort
  let [mock, spies] = SpyDict({
  \   'greet': { name -> 'Hello ' . name . '!' },
  \ })

  call assert_true(has_key(mock, 'greet'))
  call assert_true(has_key(spies, 'greet'))
  call assert_equal(0, spies.greet.call_count())

  call assert_equal('Hello Vim!', mock.greet('Vim'))
  call assert_equal(1, spies.greet.call_count())
  call assert_equal([['Vim']], spies.greet.args())
  call assert_equal(['Vim'], spies.greet.last_args())
  call assert_equal(['Hello Vim!'], spies.greet.return_values())
  call assert_equal('Hello Vim!', spies.greet.last_return_value())
  call assert_equal([mock], spies.greet.selves())
  call assert_equal(mock, spies.greet.last_self())
endfunction

let g:loaded_spy = 1
