" Transparent editing of gpg encrypted files.
" By Wouter Hanegraaff <wouter@blub.net>
augroup encrypted
  au!

  " First make sure nothing is written to ~/.viminfo while editing
  " an encrypted file.
  autocmd BufReadPre,FileReadPre      *.asc set viminfo=
  " We don't want a swap file, as it writes unencrypted data to disk
  autocmd BufReadPre,FileReadPre      *.asc set noswapfile
  " Switch to binary mode to read the encrypted file
  autocmd BufReadPre,FileReadPre      *.asc set bin
  autocmd BufReadPre,FileReadPre      *.asc let ch_save = &ch|set ch=2
  autocmd BufReadPost,FileReadPost    *.asc '[,']!gpg -qd 2> /dev/null
  " Switch to normal mode for editing
  autocmd BufReadPost,FileReadPost    *.asc set nobin
  autocmd BufReadPost,FileReadPost    *.asc let &ch = ch_save|unlet ch_save
  autocmd BufReadPost,FileReadPost    *.asc execute ":doautocmd BufReadPost " . expand("%:r")
  autocmd BufReadPost,FileReadPost    *.asc set ff=unix

  " Convert all text to encrypted text before writing
  autocmd BufWritePre,FileWritePre    *.asc   '[,']!gpg --default-recipient-self -ae 2>/dev/null
  " Undo the encryption so we are back in the normal text, directly
  " after the file has been written.
  autocmd BufWritePost,FileWritePost    *.asc   u

  " First make sure nothing is written to ~/.viminfo while editing
  " an encrypted file.
  autocmd BufReadPre,FileReadPre      *.gpg set viminfo=
  " We don't want a swap file, as it writes unencrypted data to disk
  autocmd BufReadPre,FileReadPre      *.gpg set noswapfile
  " Switch to binary mode to read the encrypted file
  autocmd BufReadPre,FileReadPre      *.gpg set bin
  autocmd BufReadPre,FileReadPre      *.gpg let ch_save = &ch|set ch=2
  autocmd BufReadPost,FileReadPost    *.gpg '[,']!gpg -qd 2> /dev/null
  " Switch to normal mode for editing
  autocmd BufReadPost,FileReadPost    *.gpg set nobin
  autocmd BufReadPost,FileReadPost    *.gpg let &ch = ch_save|unlet ch_save
  autocmd BufReadPost,FileReadPost    *.gpg execute ":doautocmd BufReadPost " . expand("%:r")
  autocmd BufReadPost,FileReadPost    *.gpg set ff=unix

  " Convert all text to encrypted text before writing
  autocmd BufWritePre,FileWritePre    *.gpg   '[,']!gpg --default-recipient-self -e 2>/dev/null
  " Undo the encryption so we are back in the normal text, directly
  " after the file has been written.
  autocmd BufWritePost,FileWritePost    *.gpg   u
augroup END
