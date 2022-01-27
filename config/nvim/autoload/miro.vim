function! miro#get_url(opts, ...) abort
  if a:0 || type(a:opts) != type({})
    return ''
  endif

  let l:type = get(a:opts, 'type', '')
  let l:p = get(a:opts, 'path', '')
  let l:path = substitute(l:p, '^/', '', '')
  let l:line1  = get(a:opts, 'line1')
  let l:line2  = get(a:opts, 'line2')
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
  " echom a:opts
  let l:head = a:opts.commit

  if a:opts.commit =~? '[^0-9]'
    let l:head = fugitive#Head()
  endif

  " If buffer contains directory not file, return a /tree url
  if l:type ==# 'tree' || l:p =~# '/$'
    let l:url = l:root . '/browse/' .  l:path
  elseif l:type ==# 'blob' || l:p =~# '[^/]$'
    " If we have ranges prefer normal view
    " otherwise go to commit view because we can't highlight lines in commit view
    let l:url = l:root . '/browse/' .  l:path . '?at=refs/heads/' . l:head

    if l:line1 !=# ''
      let l:url .= '#' . a:opts.line1
      if l:line2 !=# ''
        let l:url .= '-' . a:opts.line2
      endif
      " else
      "   if l:commit !=# ''
      "     let l:url = l:root . '/commits/' .  l:commit . '#' . l:path
      "   endif
    endif
  endif

  return l:url
endfunction
