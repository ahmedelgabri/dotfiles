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
let g:startify_enable_special = 0
let g:startify_files_number = 10
let g:startify_session_persistence = 1
let g:startify_session_delete_buffers = 1
let g:startify_ascii = [' ', ' ϟ ' . (has('nvim') ? 'nvim' : 'vim') . '.', ' ']
let g:startify_custom_header = 'map(startify#fortune#boxed() + g:startify_ascii, "repeat(\" \", 5).v:val")'
let g:startify_custom_header_quotes = startify#fortune#predefined_quotes() + [
      \ ['Simplicity is a great virtue but it requires hard work to achieve it', 'and education to appreciate it. And to make matters worse: complexity sells better.', '', '― Edsger W. Dijkstra'],
      \ ['A common fallacy is to assume authors of incomprehensible code will be able to express themselves clearly in comments.'],
      \ ['Your time is limited, so don’t waste it living someone else’s life. Don’t be trapped by dogma — which is living with the results of other people’s thinking. Don’t let the noise of others’ opinions drown out your own inner voice. And most important, have the courage to follow your heart and intuition. They somehow already know what you truly want to become. Everything else is secondary.', '', '— Steve Jobs, June 12, 2005'],
      \ ['My take: Animations are something you earn the right to include when the rest of the experience is fast and intuitive.', '', '— @jordwalke'],
      \ ['If a feature is sometimes dangerous, and there is a better option, then always use the better option.', '', '- Douglas Crockford'],
      \ ['The best way to make your dreams come true is to wake up.', '', '― Paul Valéry'],
      \ ['Fast is slow, but continuously, without interruptions', '', '– Japanese proverb'],
      \ ['A language that doesn’t affect the way you think about programming is not worth knowing.', '- Alan Perlis'],
      \ ['Bad programmers worry about the code. Good programmers worry about data structures and their relationships', '' , '― Linus Torvalds'],
      \ ['Work expands to fill the time available for its completion.', '', "― C. Northcote Parkinson (Parkinson's Law)"],
      \ ['Hard Choices, Easy Life. Easy Choices, Hard Life.', '', '― Jerzy Gregory'],
      \ ['Future regret minimization is a powerful force for good judgement.', '', '― Tobi Lutke'],
      \ ['The works must be conceived with fire in the soul but executed with clinical coolness', '', '― Joan Miró'],
      \ ['Believe those who seek the truth, doubt those who find it.', '', '― André Gide'],
      \ ["Argue like you're right. Listen like you're wrong", '', '― Adam M. Grant'],
      \ ['Luck is what happens when preparation meets opportunity.', '', '― Seneca']
      \ ]

function! s:list_commits()
  let git = 'git -C '. getcwd()
  let commits = systemlist(git .' log --no-decorate --oneline -n 10')

  " if we are not inside a git repo don't show anything
  if commits[0] =~? '^fatal:'
    return []
  endif

  " let git = 'G'. git[1:] " fugitive doesn't support -C flag https://github.com/tpope/vim-fugitive/blob/511d3035d4da2453a9cb0188b6020ed7bc8fc18f/autoload/fugitive.vim#L2477-L2478
  let git = 'Git'

  return map(commits, '{"line": matchstr(v:val, "\\s\\zs.*"), "cmd": "'. git .' show ". matchstr(v:val, "^\\x\\+") }')
endfunction

let g:startify_lists = [
      \ { 'header': ['   Sessions'], 'type': 'sessions' },
      \ { 'header': ['   MRU [' . getcwd() . ']'], 'type': 'dir' },
      \ { 'header': ['   Files'], 'type': 'files' },
      \ { 'header': ['   Commits'], 'type': function('s:list_commits') },
      \ { 'header': ['   Commands'], 'type': 'commands' },
      \ { 'header': ['   Bookmarks'], 'type': 'bookmarks' }
      \ ]

let g:startify_skiplist = [
      \ 'COMMIT_EDITMSG',
      \ '^/tmp',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc',
      \ 'plugged/.*/doc',
      \ 'pack/.*/doc',
      \ '.*/vimwiki/.*'
      \ ]

augroup MyStartify
  autocmd!
  autocmd User Startified setlocal cursorline
augroup END
