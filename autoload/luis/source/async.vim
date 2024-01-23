let s:INVALID_JOB = 0
let s:INVALID_SESSION = 0
let s:INVALID_TIMER = -1

function! luis#source#async#new(name, default_kind, command, ...) abort
  let options = get(a:000, 0, {})
  let source = copy(s:Source)
  let source.name = 'async/' . a:name
  let source.default_kind = a:default_kind
  let source.command = a:command
  let source.to_candidate = has_key(options, 'to_candidate')
  \                       ? options.to_candidate
  \                       : { line -> { 'word': line } }
  let source.debounce_time = get(options, 'debounce_time', 0)
  let source.current_job = s:INVALID_JOB
  let source.current_session = s:INVALID_SESSION
  let source.current_timer = s:INVALID_TIMER
  let source.sequence = 0
  let source.last_line = 0
  let source.last_pattern = 0
  let source.current_candidates = []
  let source.pending_candidates = []
  return source
endfunction

let s:Source = {
\   'matcher': luis#matcher#through#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  if self.current_job isnot s:INVALID_JOB
  \  && (self.last_pattern is 0 || a:context.pattern !=# self.last_pattern)
    let self.last_pattern = a:context.pattern
    if self.current_timer isnot s:INVALID_TIMER
      call timer_stop(self.current_timer)
    endif
    if self.debounce_time > 0
      let self.current_timer = timer_start(self.debounce_time, self._on_timer)
    else
      call s:send_pattern(self)
    endif
  endif
  return self.current_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  if has('nvim')
    let self.current_job = jobstart(self.command, {
    \   'on_exit': function(self._on_exit, [], self),
    \   'on_stdout': function(self._on_stdout, [], self),
    \ })
  else
    let self.current_job = job_start(self.command, {
    \   'out_cb': self._out_cb,
    \   'exit_cb': self._exit_cb,
    \ })
    let status = job_status(self.current_job)
    if status ==# 'fail'
      let self.current_job = s:INVALID_JOB
    endif
  endif
  let self.current_session = a:context.session
  let self.last_line = ''
  let self.sequence = 0
endfunction

function! s:Source.on_source_leave(context) abort dict
  if self.current_job isnot s:INVALID_JOB
    if has('nvim')
      call jobclose(self.current_job)
    else
      call job_stop(self.current_job)
    endif
    let self.current_job = s:INVALID_JOB
  endif
  let self.current_session = s:INVALID_SESSION
endfunction

function! s:Source._out_cb(job, message) abort dict
  let is_eof = 0

  for line in split(a:message, "\n")
    if s:process_line(self, line)
      let is_eof = 1
    endif
  endfor

  if is_eof
  \  && self.current_session isnot s:INVALID_SESSION
  \  && self.current_session.ui.is_active()
    call self.current_session.ui.refresh_candidates()
  endif
endfunction

function! s:Source._on_exit(job, exit_code, event) abort
  if self.current_job == a:job
    let self.current_job = s:INVALID_JOB
  endif
endfunction

function! s:Source._on_stdout(job, data, event) abort dict
  let is_eof = 0

  let line = self.last_line . a:data[0]
  if line != ''
    if s:process_line(self, line)
      let is_eof = 1
    endif
  endif

  for line in a:data[1:-2]
    if s:process_line(self, line)
      let is_eof = 1
    endif
  endfor

  let self.last_line = a:data[-1]

  if is_eof
  \  && self.current_session isnot s:INVALID_SESSION
  \  && self.current_session.ui.is_active()
    call self.current_session.ui.refresh_candidates()
  endif
endfunction

function! s:Source._on_timer(timer) abort dict
  if self.current_job isnot s:INVALID_JOB
    call s:send_pattern(self)
  endif
  let self.current_timer = s:INVALID_TIMER
endfunction

function! s:Source._exit_cb(job, status) abort dict
  if self.current_job is a:job
    let self.current_job = s:INVALID_JOB
  endif
endfunction

function! s:process_line(source, line) abort
  let components = split(a:line, '^[^ ]\+\zs ', 1)
  if components[0] != a:source.sequence
    return 0
  endif

  if len(components) == 1  " EOF
    let a:source.current_candidates = a:source.pending_candidates
    return 1
  else
    let rest = join(components[1:], ' ')
    let candidate = a:source.to_candidate(rest)
    if type(candidate) is v:t_dict
      call add(a:source.pending_candidates, candidate)
    endif
    return 0
  endif
endfunction

function! s:send_pattern(source) abort
  let a:source.pending_candidates = []
  let a:source.sequence += 1
  let payload = a:source.sequence . ' ' . a:source.last_pattern . "\n"
  if has('nvim')
    call chansend(a:source.current_job, payload)
  else
    call ch_sendraw(a:source.current_job, payload)
  endif
endfunction
