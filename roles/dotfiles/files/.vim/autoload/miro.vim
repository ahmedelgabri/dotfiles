function! miro#register(name) abort
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
endfunction

function! miro#get_url(opts, ...) abort
  if a:0 || type(a:opts) != type({})
    return ''
  endif

  let l:path = substitute(a:opts.path, '^/', '', '')
  let l:domain_pattern = ''
  let l:domains = exists('g:fugitive_miro_domains') ? g:fugitive_miro_domains : []

  for l:domain in l:domains
    let l:domain_pattern .= '\|' . escape(split(l:domain, '://')[-1], '.')
  endfor

  let l:repo = matchstr(a:opts.remote,'^\%(https\=://\%([^@/:]*@\)\=\|git://\|git@\|ssh://git@\)\=\zs\('.l:domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=/\=$')

  if l:repo ==# ''
    return ''
  endif

  let [l:domain_port, l:project, l:repo_name] = split(l:repo, '/')
  let l:repo = join([l:domain_port, l:project, 'repos', l:repo_name], '/')
  let l:root = (index(l:domains, 'http://' . matchstr(l:repo, '^[^:/]*')) >= 0 ? 'http://' : 'https://') . substitute(l:repo,':\d*','/projects','')
  let l:commit = a:opts.repo.head()
  let l:url = l:root . '/browse/' .  l:path . '?at=refs/heads/' . l:commit

  if get(a:opts, 'line1')
    let l:url .= '#' . a:opts.line1

    if get(a:opts, 'line2')
      let l:url .= '-' . a:opts.line2
    endif
  endif

  return l:url
endfunction
