let s:INVALID_JOB = 0
let s:INVALID_TIMER = -1

function! luis#source#async#new(name, default_kind, command, ...) abort
  let options = get(a:000, 0, {})
  let source = copy(s:Source)
  let source.name = a:name
  let source.default_kind = a:default_kind
  let source._command = a:command
  let source._selector_func = has_key(options, 'selector_func')
  \                         ? options.selector_func
  \                         : { line -> { 'word': line } }
  let source._debounce_time = get(options, 'debounce_time', 0)
  let source._job = s:INVALID_JOB
  let source._timer = s:INVALID_TIMER
  let source._sequence = 0
  let source._last_line = 0
  let source._last_pattern = 0
  let source._current_candidates = []
  let source._pending_candidates = []
  return source
endfunction

let s:Source = {
\   'matcher': g:luis#matcher#through#export,
\ }

function! s:Source.gather_candidates(context) abort dict
  if self._job isnot s:INVALID_JOB
  \  && (self._last_pattern is 0 || a:context.pattern !=# self._last_pattern)
    let self._last_pattern = a:context.pattern
    if self._timer isnot s:INVALID_TIMER
      call timer_stop(self._timer)
    endif
    if self._debounce_time > 0
      let Callback = function('s:on_timer', [], self)
      let self._timer = timer_start(self._debounce_time, Callback)
    else
      call self._send_pattern()
    endif
  endif
  return self._current_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  if has('nvim')
    let self._job = jobstart(self._command, {
    \   'on_stdout': function('s:on_nvim_stdout', [], self),
    \   'on_exit': function('s:on_nvim_exit', [], self),
    \ })
  else
    let self._job = job_start(self._command, {
    \   'out_cb': function('s:on_vim_stdout', [], self),
    \   'exit_cb': function('s:on_vim_exit', [], self),
    \ })
    if job_status(self._job) ==# 'fail'
      let self._job = s:INVALID_JOB
    endif
  endif
  let self._sequence = 0
  let self._last_line = ''
endfunction

function! s:Source.on_source_leave() abort dict
  if self._job isnot s:INVALID_JOB
    if has('nvim')
      call jobclose(self._job)
    else
      call job_stop(self._job)
    endif
    let self._job = s:INVALID_JOB
  endif
endfunction

function! s:Source._send_pattern() abort dict
  let self._pending_candidates = []
  let self._sequence += 1
  let payload = self._sequence . ' ' . self._last_pattern . "\n"
  if has('nvim')
    call chansend(self._job, payload)
  else
    call ch_sendraw(self._job, payload)
  endif
endfunction

function! s:Source._process_line(line) abort dict
  let components = split(a:line, '^\d\+\zs\s', 1)
  if components[0] != self._sequence
    return 0
  endif

  if len(components) == 1  " EOF
    let self._current_candidates = self._pending_candidates
    return 1
  else
    let candidate = self._selector_func(components[1])
    if candidate isnot 0
      call add(self._pending_candidates, candidate)
    endif
    return 0
  endif
endfunction

function! s:on_nvim_exit(job, exit_code, event) abort dict
  if self._job == a:job
    let self._job = s:INVALID_JOB
  endif
endfunction

function! s:on_nvim_stdout(job, data, event) abort dict
  let is_eof = 0

  let line = self._last_line . a:data[0]
  if line != ''
    if self._process_line(line)
      let is_eof = 1
    endif
  endif

  for line in a:data[1:-2]
    if self._process_line(line)
      let is_eof = 1
    endif
  endfor

  let self._last_line = a:data[-1]

  if is_eof
    call luis#update_candidates()
  endif
endfunction

function! s:on_timer(timer) abort dict
  if self._job isnot s:INVALID_JOB
    call self._send_pattern()
  endif
  let self._timer = s:INVALID_TIMER
endfunction

function! s:on_vim_exit(job, status) abort dict
  if self._job is a:job
    let self._job = s:INVALID_JOB
  endif
endfunction

function! s:on_vim_stdout(job, message) abort dict
  let is_eof = 0

  for line in split(a:message, "\n")
    if self._process_line(line)
      let is_eof = 1
    endif
  endfor

  if is_eof
    call luis#update_candidates()
  endif
endfunction
