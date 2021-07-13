" https://vimways.org/2019/personal-notetaking-in-vim/
" https://danishpraka.sh/2020/02/23/journaling-in-vim.html

func! GetNotesCompletion(ArgLead, CmdLine, CursorPos) abort
  return luaeval("require'_.notes'.get_notes_completion()")
endfunc

command! -complete=customlist,GetNotesCompletion -nargs=* Note lua require'_.notes'.note_edit(<f-args>)
command! -complete=customlist,GetNotesCompletion -nargs=* ONote lua require'_.notes'.note_in_obsidian(<f-args>)
command! -nargs=* Wiki lua require'_.notes'.wiki_edit(<f-args>)
command! -nargs=* -bang Notes lua require'_.notes'.search_notes(<q-args>, <bang>0)

nnoremap <silent> <leader>sn :Notes<CR>
nnoremap <silent> <localleader>o :lua require'_.notes'.open_in_obsidian()<CR>
