setl conceallevel=2
setl concealcursor=n

let s:package_lock = findfile('package-lock.json', expand('%:p').';')

if filereadable(s:package_lock)
  setlocal makeprg=npm
else
  setlocal makeprg=yarn
endif

