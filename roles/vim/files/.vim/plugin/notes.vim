" https://vimways.org/2019/personal-notetaking-in-vim/
" https://danishpraka.sh/2020/02/23/journaling-in-vim.html

func! GetNotesCompletion(ArgLead, CmdLine, CursorPos) abort
  return luaeval("require'_/notes'.get_notes_completion(_A[1], _A[2], _A[3])", [ArgLead, CmdLine, CursorPos])
endfunc

command! -complete=customlist,GetNotesCompletion -nargs=* Note lua require'_/notes'.note_edit({<f-args>})
command! -nargs=* Wiki lua require'_/notes'.wiki_edit({<f-args>})
command! -bang Notes lua require'_/notes'.search_notes()

nnoremap <silent> <leader>sn :Notes<CR>
