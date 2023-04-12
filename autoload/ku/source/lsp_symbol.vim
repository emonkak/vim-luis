function! ku#source#lsp_symbol#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  let source._sequence = 0
  return source
endfunction

let s:Source = {
\   'name': 'lsp_symbol',
\   'default_kind': g:ku#kind#file#export,
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let bufnr = bufnr('#')
  let self._cached_candidates = []
  let self._sequence += 1
  for server in s:available_servers(bufnr)
    call lsp#send_request(server, {
    \   'method': 'textDocument/documentSymbol',
    \   'params': {
    \     'textDocument': lsp#get_text_document_identifier(bufnr),
    \   },
    \   'on_notification': function('s:on_notification',
    \                               [server, self._sequence],
    \                               self),
    \ })
  endfor
endfunction

function! s:available_servers(bufnr) abort
  return filter(lsp#get_allowed_servers(a:bufnr),
  \             'lsp#capabilities#has_document_symbol_provider(v:val)')
endfunction

function! s:candidate_from_symbol(server, symbol, depth) abort
  let location = a:symbol.location
  let path = lsp#utils#uri_to_path(location.uri)
  let cursor = lsp#utils#position#lsp_to_vim(path, location.range.start)
  let indent = repeat('  ', a:depth)
  let kind = lsp#ui#vim#utils#_get_symbol_text_from_kind(a:server, a:symbol.kind)
  return {
  \   'word': a:symbol.name,
  \   'abbr': indent . a:symbol.name,
  \   'menu': kind,
  \   'user_data': {
  \     'ku_file_path': path,
  \     'ku_cursor': cursor,
  \   },
  \   'ku__sort_priority': cursor[0] * 10000 + cursor[1],
  \ }
endfunction

function! s:on_notification(server, sequence, data) abort dict
  if !has_key(a:data.response, 'result') || self._sequence != a:sequence
    return
  endif

  let symbols = type(a:data.response.result) == v:t_dict
  \             ? [a:data.response.result]
  \             : a:data.response.result
  if empty(symbols)  " some servers also return null
    return
  endif

  let queue = []
  let depth = 0
  let changed_p = 0

  while 1
    for symbol in symbols
      if lsp#utils#is_file_uri(symbol.location.uri)
        let candidate = s:candidate_from_symbol(a:server, symbol, depth)
        call add(self._cached_candidates, candidate)
        let changed_p = 1
      endif
      if has_key(symbol, 'children') && !empty(symbol.children)
        call add(queue, [depth + 1, symbol.children])
      endif
    endfor
    if empty(queue)
      break
    endif
    let [depth, symbols] = remove(queue, 0)
  endwhile

  if changed_p
    call ku#request_update_candidates()
  endif
endfunction
