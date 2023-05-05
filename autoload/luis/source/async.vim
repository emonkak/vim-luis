let s:INVALID_JOB = 0
let s:INVALID_TIMER = -1

function! luis#source#async#new(name, default_kind, command, ...) abort
  let options = get(a:000, 0, {})
  let source = copy(s:Source)
  let source.name = 'async/' . a:name
  let source.default_kind = a:default_kind
  let source._command = a:command
  let source._to_candidate = has_key(options, 'to_candidate')
  \                        ? options.to_candidate
  \                        : { line -> { 'word': line } }
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
      let Callback = function('s:on_timer', [self])
      let self._timer = timer_start(self._debounce_time, Callback)
    else
      call s:send_pattern(self)
    endif
  endif
  return self._current_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  if has('nvim')
    let self._job = jobstart(self._command, {
    \   'on_stdout': function('s:on_nvim_stdout', [self]),
    \   'on_exit': function('s:on_nvim_exit', [self]),
    \ })
  else
    let self._job = job_start(self._command, {
    \   'out_cb': function('s:on_vim_stdout', [self]),
    \   'exit_cb': function('s:on_vim_exit', [self]),
    \ })
    let status = job_status(self._job)
    if status ==# 'fail'
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

function! s:on_nvim_exit(source, job, exit_code, event) abort
  if a:source._job == a:job
    let a:source._job = s:INVALID_JOB
  endif
endfunction

function! s:on_nvim_stdout(source, job, data, event) abort
  let is_eof = 0

  let line = a:source._last_line . a:data[0]
  if line != ''
    if s:process_line(a:source, line)
      let is_eof = 1
    endif
  endif

  for line in a:data[1:-2]
    if s:process_line(a:source, line)
      let is_eof = 1
    endif
  endfor

  let a:source._last_line = a:data[-1]

  if is_eof
    call luis#update_candidates()
  endif
endfunction

function! s:on_timer(source, timer) abort
  if a:source._job isnot s:INVALID_JOB
    call s:send_pattern(a:source)
  endif
  let a:source._timer = s:INVALID_TIMER
endfunction

function! s:on_vim_exit(source, job, status) abort
  if a:source._job is a:job
    let a:source._job = s:INVALID_JOB
  endif
endfunction

function! s:on_vim_stdout(source, job, message) abort
  let is_eof = 0

  for line in split(a:message, "\n")
    if s:process_line(a:source, line)
      let is_eof = 1
    endif
  endfor

  if is_eof
    call luis#update_candidates()
  endif
endfunction

function! s:process_line(source, line) abort
  let components = split(a:line, '^[^ ]\+\zs ', 1)
  if components[0] != a:source._sequence
    return 0
  endif

  if len(components) == 1  " EOF
    let a:source._current_candidates = a:source._pending_candidates
    return 1
  else
    let rest = join(components[1:], ' ')
    let candidate = a:source._to_candidate(rest)
    if candidate isnot 0
      call add(a:source._pending_candidates, candidate)
    endif
    return 0
  endif
endfunction

function! s:send_pattern(source) abort
  let a:source._pending_candidates = []
  let a:source._sequence += 1
  let payload = a:source._sequence . ' ' . a:source._last_pattern . "\n"
  if has('nvim')
    call chansend(a:source._job, payload)
  else
    call ch_sendraw(a:source._job, payload)
  endif
endfunction
