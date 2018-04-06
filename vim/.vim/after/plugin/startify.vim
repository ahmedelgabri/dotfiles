scriptencoding utf-8

if !exists(':Startify')
  finish
endif

let g:startify_padding_left = 5
let g:startify_relative_path = 1
let g:startify_fortune_use_unicode = 1
let g:startify_change_to_vcs_root = 1
let g:startify_update_oldfiles = 1
let g:startify_use_env = 1
let g:startify_files_number = 6
let g:startify_session_persistence = 1
let g:startify_session_delete_buffers = 1

if has('nvim')
  let s:ascii = [
        \ '           _     ',
        \ '  __ _  __(_)_ _ ',
        \ ' /  \ |/ / /  / \',
        \ '/_/_/___/_/_/_/_/',
        \ '']
else
  let s:ascii = [
        \ '       _     ',
        \ ' _  __(_)_ _ ',
        \ '| |/ / /  / \',
        \ '|___/_/_/_/_/',
        \ '']
endif

let g:startify_ascii = [
      \ '',
      \ '        ,/     ',
      \ "      ,'/      ",
      \ "    ,' /       ". s:ascii[0],
      \ "  ,'  /_____,  ". s:ascii[1],
      \ ".'____    ,'   ". s:ascii[2],
      \ "     /  ,'     ". s:ascii[3],
      \ "    / ,'       ",
      \ "   /,'         ",
      \ "  /'           ",
      \ ''
      \ ]

let g:startify_custom_header = 'map(g:startify_ascii + startify#fortune#boxed(), "repeat(\" \", 5).v:val")'
let g:startify_custom_header_quotes = startify#fortune#predefined_quotes() + [
      \ ['Simplicity is a great virtue but it requires hard work to achieve it', 'and education to appreciate it. And to make matters worse: complexity sells better.', '', '― Edsger W. Dijkstra'],
      \ ['A common fallacy is to assume authors of incomprehensible code will be able to express themselves clearly in comments.'],
      \ ['Your time is limited, so don’t waste it living someone else’s life. Don’t be trapped by dogma — which is living with the results of other people’s thinking. Don’t let the noise of others’ opinions drown out your own inner voice. And most important, have the courage to follow your heart and intuition. They somehow already know what you truly want to become. Everything else is secondary.', '', '— Steve Jobs, June 12, 2005'],
      \ ['My take: Animations are something you earn the right to include when the rest of the experience is fast and intuitive.', '', '— @jordwalke'],
      \ ['If a feature is sometimes dangerous, and there is a better option, then always use the better option.', '', '- Douglas Crockford'],
      \ ['The best way to make your dreams come true is to wake up.', '', '― Paul Valéry'],
      \ ['Fast is slow, but continuously, without interruptions', '', '– Japanese proverb'],
      \ ]

let g:startify_list_order = [
      \ ['   Sessions:'], 'sessions',
      \ ['   Files:'], 'dir',
      \ ['   MRU'], 'files',
      \ ['   Bookmarks:'], 'bookmarks',
      \ ]
let g:startify_skiplist = [
      \ 'COMMIT_EDITMSG',
      \ '^/tmp',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc',
      \ 'plugged/.*/doc',
      \ ]

augroup MyStartify
  autocmd!
  autocmd User Startified setlocal cursorline
augroup END
