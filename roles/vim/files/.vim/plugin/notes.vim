" https://vimways.org/2019/personal-notetaking-in-vim/
" https://danishpraka.sh/2020/02/23/journaling-in-vim.html

command! -complete=customlist,notes#getNotesCompletion -nargs=? Note call notes#note_edit(<f-args>)
command! -nargs=? Wiki call notes#wiki_edit(<f-args>)
command! -bang Notes call fzf#vim#files(notes#getDir())

nnoremap <silent> <leader>sn :Notes<CR>
