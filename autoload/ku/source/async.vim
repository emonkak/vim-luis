" ku source: async
" Constants  "{{{1

if !exists('g:ku_source_async_runner_command')
  let g:ku_source_async_runner_command =
  \   ['fuzzy-filter', '-l', g:ku#matcher#limit_candidates, '--']
endif








" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'async',
\   'kind': g:ku#kind#file#module,
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

function! ku#source#async#new(command, SelectorFn) abort
  let name = a:command[0]
  return extend({
  \   'name': 'async/' . name,
  \   '_command': a:command,
  \   '_selector_fn': a:SelectorFn,
  \   '_channel': 0,
  \   '_pattern_count': 0,
  \   '_last_pattern': 0,
  \   '_last_line': 0,
  \   '_cached_candidates': [],
  \ }, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
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
  let self._last_pattern = 0
  let self._last_line = ''
  let self._cached_candidates = []
endfunction




function! ku#source#async#on_source_leave() abort dict "{{{2
  if self._channel isnot 0
    if has('nvim')
      call jobclose(self._channel)
    else
      call job_stop(self._channel)
    endif
  endif
endfunction




function! ku#source#async#gather_candidates(pattern) abort dict  "{{{2
  if self._channel isnot 0
  \  && (self._last_pattern is 0 || a:pattern !=# self._last_pattern)
    let self._pattern_count += 1
    let self._last_pattern = a:pattern
    let self._cached_candidates = []
    if has('nvim')
      call chansend(self._channel, a:pattern . "\n")
    else
      call ch_sendraw(self._channel, a:pattern . "\n")
    endif
  endif
  return self._cached_candidates
endfunction








" Misc.  "{{{1
function! s:on_nvim_job_stdout(channel, data, event) abort dict  "{{{2
  let has_changed = 0

  let line = self._last_line . a:data[0]
  if line != ''
    if s:process_line(self, line)
      let has_changed = 1
    endif
  endif

  for line in a:data[1:-2]
    if s:process_line(self, line)
      let has_changed = 1
    endif
  endfor

  let self._last_line = a:data[-1]

  if has_changed
    call ku#refresh_candidates()
  endif
endfunction




function! s:on_nvim_job_exit(channel, exit_code, event) abort dict  "{{{2
  if self._channel == a:channel
    let self._channel = 0
  endif
endfunction




function! s:on_vim_job_stdout(channel, message) abort dict  "{{{2
  let has_changed = 0

  for line in split(a:message, "\n")
    if s:process_line(self, line)
      let has_changed = 1
    endif
  endfor

  if has_changed
    call ku#refresh_candidates()
  endif
endfunction




function! s:on_vim_job_exit(channel, status) abort dict  "{{{2
  if self._channel == a:channel
    let self._channel = 0
  endif
endfunction




function! s:process_line(self, line) abort  "{{{2
  let components = split(a:line, '^\d\+\zs\s', 1)
  if len(components) < 2
    return 0
  endif

  let [sequence, body] = components
  if sequence != a:self._pattern_count
    return 0
  endif

  let candidate = a:self._selector_fn(body)
  if candidate is 0
    return 0
  else

  call add(a:self._cached_candidates, candidate)
  return 1
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
