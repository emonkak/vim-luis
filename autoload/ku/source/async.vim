" ku source: async
" Constants  "{{{1

let s:INVALID_CHANNEL = -1
let s:INVALID_TIMER = -1








" Variables  "{{{1

if !exists('g:ku_source_async_runner_command')
  let g:ku_source_async_runner_command =
  \   ['fuzzy-filter', '-l', g:ku#matcher#limit_candidates, '--']
endif








" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'async',
\   'matcher': {
\      'match_candidates': function('ku#matcher#any_match')
\   },
\   'gather_candidates': function('ku#source#async#gather_candidates'),
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#async#on_source_enter'),
\   'on_source_leave': function('ku#source#async#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#async#new(kind, command, SelectorFn) abort
  let name = a:command[0]
  return extend({
  \   'name': 'async/' . name,
  \   'kind': a:kind,
  \   '_command': a:command,
  \   '_selector_fn': a:SelectorFn,
  \   '_channel': s:INVALID_CHANNEL,
  \   '_timer': s:INVALID_TIMER,
  \   '_sequence': 0,
  \   '_last_line': 0,
  \   '_last_pattern': 0,
  \   '_current_candidates': [],
  \   '_pending_candidates': [],
  \ }, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#async#gather_candidates(pattern) abort dict  "{{{2
  if self._channel isnot s:INVALID_CHANNEL
  \  && (self._last_pattern is 0 || a:pattern !=# self._last_pattern)
    let self._last_pattern = a:pattern
    if self._timer isnot s:INVALID_TIMER
      call timer_stop(self._timer)
    endif
    " defer update the pattern
    let self._timer = timer_start(100, function('s:on_timer', [], self))
  endif
  return self._current_candidates
endfunction




function! ku#source#async#on_source_enter() abort dict "{{{2
  let command = g:ku_source_async_runner_command + self._command
  if has('nvim')
    let self._channel = jobstart(command, {
    \   'on_stdout': function('s:on_nvim_job_stdout', [], self),
    \   'on_exit': function('s:on_nvim_job_exit', [], self),
    \ })
  else
    let self._channel = job_start(command, {
    \   'out_cb': function('s:on_vim_job_stdout', [], self),
    \   'exit_cb': function('s:on_vim_job_exit', [], self),
    \ })
  endif
  let self._sequence = 0
  let self._last_line = ''
endfunction




function! ku#source#async#on_source_leave() abort dict "{{{2
  if self._channel isnot s:INVALID_CHANNEL
    if has('nvim')
      call jobclose(self._channel)
    else
      call job_stop(self._channel)
    endif
    let self._channel = s:INVALID_CHANNEL
  endif
endfunction








" Misc.  "{{{1
function! s:on_nvim_job_stdout(channel, data, event) abort dict  "{{{2
  let eof_was_reached_p = 0

  let line = self._last_line . a:data[0]
  if line != ''
    if s:process_line(self, line)
      let eof_was_reached_p = 1
    endif
  endif

  for line in a:data[1:-2]
    if s:process_line(self, line)
      let eof_was_reached_p = 1
    endif
  endfor

  let self._last_line = a:data[-1]

  if eof_was_reached_p
    call ku#request_update_candidates()
  endif
endfunction




function! s:on_nvim_job_exit(channel, exit_code, event) abort dict  "{{{2
  if self._channel == a:channel
    let self._channel = s:INVALID_CHANNEL
  endif
endfunction




function! s:on_vim_job_stdout(channel, message) abort dict  "{{{2
  let eof_was_reached_p = 0

  for line in split(a:message, "\n")
    if s:process_line(self, line)
      let eof_was_reached_p = 1
    endif
  endfor

  if eof_was_reached_p
    call ku#request_update_candidates()
  endif
endfunction




function! s:on_vim_job_exit(channel, status) abort dict  "{{{2
  if self._channel == a:channel
    let self._channel = s:INVALID_CHANNEL
  endif
endfunction




function! s:on_timer(timer) abort dict  "{{{2
  if self._channel isnot s:INVALID_CHANNEL
    if has('nvim')
      call chansend(self._channel, self._last_pattern . "\n")
    else
      call ch_sendraw(self._channel, self._last_pattern . "\n")
    endif
    let self._pending_candidates = []
    let self._sequence += 1
  endif
  let self._timer = s:INVALID_TIMER
endfunction




function! s:process_line(source, line) abort  "{{{2
  let components = split(a:line, '^\d\+\zs\s', 1)
  if components[0] != a:source._sequence
    return 0
  endif

  if len(components) == 1  " EOF
    let a:source._current_candidates = a:source._pending_candidates
    return 1
  else
    let candidate = a:source._selector_fn(components[1])
    if candidate isnot 0
      call add(a:source._pending_candidates, candidate)
    endif
    return 0
  endif
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
