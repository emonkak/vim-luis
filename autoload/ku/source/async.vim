" ku source: async
" Constants  "{{{1

let s:INVALID_CHANNEL = -1
let s:INVALID_TIMER = -1








" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'matcher': g:ku#matcher#raw,
\   'gather_candidates': function('ku#source#async#gather_candidates'),
\   'on_source_enter': function('ku#source#async#on_source_enter'),
\   'on_source_leave': function('ku#source#async#on_source_leave'),
\ }

let s:OPTIONS_SCHEMA = {
\   'type': 'struct',
\   'properties': {
\     'name': {
\       'type': v:t_string,
\     },
\     'default_kind': g:ku#schema#kind,
\     'command': {
\       'type': 'list',
\       'item': {
\         'type': v:t_string,
\       },
\     },
\     'selector_fn': {
\       'type': v:t_func,
\     },
\     'debounce_time': {
\       'type': v:t_number,
\     },
\   },
\ }

function! ku#source#async#new(options) abort
  call ku#schema#validate(a:options, s:OPTIONS_SCHEMA)
  return extend({
  \   'name': a:options.name,
  \   'default_kind': a:options.default_kind,
  \   '_command': a:options.command,
  \   '_selector_fn': a:options.selector_fn,
  \   '_debounce_time': get(a:options, 'debounce_time', 100),
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
    let self._timer = timer_start(self._debounce_time,
    \                             function('s:on_timer',
    \                             [],
    \                             self))
  endif
  return self._current_candidates
endfunction




function! ku#source#async#on_source_enter() abort dict "{{{2
  if has('nvim')
    let self._channel = jobstart(self._command, {
    \   'on_stdout': function('s:on_nvim_job_stdout', [], self),
    \   'on_exit': function('s:on_nvim_job_exit', [], self),
    \ })
  else
    let self._channel = job_start(self._command, {
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
  if self._channel is a:channel
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
