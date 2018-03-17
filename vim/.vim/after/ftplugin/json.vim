if executable('jq')
  setlocal formatprg=jq\ .
else
  setlocal formatprg=python\ -m\ json.tool
endif


