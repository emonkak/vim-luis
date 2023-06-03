## Luis

**Luis**, which stands for **L**ookup **UI** for **S**ources, is a Vim plugin to provide the source to gather candidates, the matcher to filter candidates by a pattern, the preview window to preview each candidate, and the UI for integrating them.

In other words, Luis is a framework for creating your own fuzzy finder.

## Features

- Pure VimScript implementation, so it works with both Vim and NeoVim.
- All components are modularized and only autoloaded when needed.
- A simple UI implementation using built-in insert completion popup menu
- You can easily create your own source with just a few lines of code, without
  creating a new file.
- Using an async source, you can ultra-fast matching for a huge amount of
  candidates.
- Using a hook, you can customize the behavior of existing sources.

## Usage

The only way to start Luis is to execute the `luis#start()` function. No commands or key mappings aren't defined by default. First of all, let's create a simple wrapper function to start the Popup Menu UI session:

```vim
function! s:luis_start(source, options = {}) abort
  " Create a new session of the Popup Menu UI (Currently, it is the only
  " implementation for UI).
  let session = luis#ui#popupmenu#new_session(a:source, a:options)
  " Start the session and store the session in the session manager globally.
  return luis#start(session)
endfunction
```

Secondly, define commands and key mappings (of course, defining only the mappings also fine), such as the following:

```vim
command! LuisBuffer  :<C-u>call <SID>luis_start(luis#source#buffer())<CR>
command! LuisFile  :<C-u>call <SID>luis_start(luis#source#file())<CR>

nnoremap <Leader>b  :<C-u>LuisBuffer<CR>
nnoremap <Leader>f  :<C-u>LuisFile<CR>
```

In this way, you have learned a means to start Luis with any UI and source. Next, let's explain about how to use Popup Menu UI.

**[Image Here]**

- If you find what you want in the menu, choose it with <kbd>&lt;C-n&gt;</kbd> or <kbd>&lt;C-p&gt;</kbd>. If the first candidate in the menu is what you want, you don't have to choose it.
- Then you can take an action on the candidate with <kbd>&lt;Enter&gt;</kbd> or <kbd>&lt;Tab&gt;</kbd>.
  - With <kbd>&lt;Enter&gt;</kbd>, Luis executes the default action for the candidate.
  - With <kbd>&lt;Tab&gt;</kbd>, Luis shows a list of available actions for the candidate. Each action is labeled with a key to execute it. If you type one of the keys, the corresponding action will be executed.
- If you don't want to take any action and stop to select, typing <kbd>&lt;Esc&gt;</kbd> or <kbd>&lt;C-c&gt;</kbd> will close the window showing the menu and quit the session.

## Customization

## Acknowledgment

Luis is a fork of the [ku](https://github.com/kana/vim-ku). I extend my thanks to [kana](https://github.com/kana) for developing ku.
