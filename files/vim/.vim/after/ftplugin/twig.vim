" stolen from https://github.com/filipekiss/dotfiles/blob/a28193f2a8317dba51109dc0421bfa66d51618c3/config/vim/ftplugin/twig.vim

scriptencoding utf-8

setlocal commentstring={#\ \ %s\ #}

if exists('b:match_words')
  let b:twigMatchWords = [
        \ ['block', 'endblock'],
        \ ['for', 'endfor'],
        \ ['macro', 'endmacro'],
        \ ['embed', 'endembed'],
        \ ['set', 'endset'],
        \ ['if', 'elseif', 'else', 'endif']
        \]
  for s:element in b:twigMatchWords
    let s:pattern = ''
    for s:tag in s:element[:-2]
      if s:pattern !=# ''
        let s:pattern .= ':'
      endif
      " This pattern is a little weird but it's vim's own pattern. See below for what every
      " piece does
      let s:pattern .= '{%\s*\<' . s:tag . '\>\s*\%(.*=\)\@![^}]\{-}%}'
      "                 ││ │  │              │ │ │          │   │
      "                 ││ │  │              │ │ │          │   └───── \{-}        - match as many as needed until next char
      "                 ││ │  │              │ │ │          └───────── [^}]        - match until a close bracket is found, excluding
      "                 ││ │  │              │ │ └──────────────────── \%(.*=\)\@! - Negative lookahead - Don't try to match if there's an equal sign at the opening tag
      "                 ││ │  │              │ └────────────────────── \s*         - match zero or more whitespaces
      "                 ││ │  │              └──────────────────────── \>          - vim's word delimiter end
      "                 ││ │  └─────────────────────────────────────── \<          - vim's word delimiter start
      "                 ││ └────────────────────────────────────────── \s*         - match zero or more whitespaces
      "                 │└──────────────────────────────────────────── %           - match a literal %
      "                 └───────────────────────────────────────────── {           - match a literal {
      "
    endfor
    let s:pattern .= ':{%\s*\<' . s:element[-1:][0] . '\>\s*.\{-}%}'
    let b:match_words .= ',' . s:pattern
  endfor
endif

let b:undo_ftplugin ='setl commentstring< | unlet! b:twigMatchWords b:match_words'
