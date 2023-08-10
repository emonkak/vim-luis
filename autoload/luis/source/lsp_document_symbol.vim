function! luis#source#lsp_document_symbol#new(bufnr) abort
  let source = copy(s:Source)
  let source.bufnr = a:bufnr
  let source.cached_candidates = []
  let source.cancel_func = 0
  return source
endfunction

let s:Source = {
\   'name': 'lsp/document_symbol',
\   'default_kind': luis#kind#buffer#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let source = self
  let session = a:context.session
  function! self.callback(symbols) abort closure
    let candidates = []
    call s:aggregate_candidates(a:symbols, source.bufnr, candidates, 1)
    let source.cached_candidates = candidates
    if session.ui.is_active()
      call session.ui.refresh_candidates()
    endif
    let source.cancel_func = 0
  endfunction
  let callback_name = get(function(self.callback), 'name')
  let self.cancel_func = s:request_document_symbol(self.bufnr, callback_name)
endfunction

function! s:Source.on_source_leave(context) abort dict
  if self.cancel_func isnot 0
    call self.cancel_func()
    let self.cancel_func = 0
  endif
endfunction

function! s:aggregate_candidates(symbols, bufnr, candidates, level) abort
  for symbol in a:symbols
    let cursor = [
    \   symbol.range.start.line + 1,
    \   symbol.range.start.character + 1,
    \ ]
    let indent = repeat(' ', (a:level - 1) * 2)
    call add(a:candidates, {
    \   'word': symbol.name,
    \   'abbr': indent . symbol.name,
    \   'kind': s:symbol_kind_to_string(symbol.kind),
    \   'menu': get(symbol, 'detail', ''),
    \   'dup': 1,
    \   'user_data': {
    \     'buffer_nr': a:bufnr,
    \     'buffer_cursor': cursor,
    \     'preview_bufnr': a:bufnr,
    \     'preview_cursor': cursor,
    \   },
    \   'luis_sort_priority': -symbol.range.start.line,
    \ })
    if has_key(symbol, 'children')
      call s:aggregate_candidates(
      \   symbol.children,
      \   a:bufnr,
      \   a:candidates,
      \   a:level + 1
      \ )
    endif
  endfor
endfunction

let s:request_document_symbol =<< END
function(bufnr, vim_callback)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
  }
  local callback = function(responses)
    local symbols = {}
    if responses ~= nil then
      for _, response in ipairs(responses) do
        if response.result ~= nil then
          for _, symbol in ipairs(response.result) do
            table.insert(symbols, symbol)
          end
        end
      end
    end
    vim.fn.call(vim_callback, { symbols }, vim.empty_dict())
  end
  return vim.lsp.buf_request_all(
    bufnr,
    'textDocument/documentSymbol',
    params,
    callback
  )
end
END
let s:request_document_symbol = luaeval(join(s:request_document_symbol, "\n"))

function! s:symbol_kind_to_string(kind) abort
  let expr = printf('vim.lsp.protocol.SymbolKind[%d] or "Unknown"', a:kind)
  return luaeval(expr)
endfunction
