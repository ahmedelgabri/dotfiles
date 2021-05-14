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
      \ ['Simplicity is a great virtue but it requires hard work to achieve it', 'and education to appreciate it. And to make matters worse: complexity sells better.', '', '— Edsger W. Dijkstra'],
      \ ['A common fallacy is to assume authors of incomprehensible code will be able to express themselves clearly in comments.'],
      \ ['Your time is limited, so don’t waste it living someone else’s life. Don’t be trapped by dogma — which is living with the results of other people’s thinking. Don’t let the noise of others’ opinions drown out your own inner voice. And most important, have the courage to follow your heart and intuition. They somehow already know what you truly want to become. Everything else is secondary.', '', '— Steve Jobs, June 12, 2005'],
      \ ['My take: Animations are something you earn the right to include when the rest of the experience is fast and intuitive.', '', '— @jordwalke'],
      \ ['If a feature is sometimes dangerous, and there is a better option, then always use the better option.', '', '- Douglas Crockford'],
      \ ['The best way to make your dreams come true is to wake up.', '', '— Paul Valéry'],
      \ ['Fast is slow, but continuously, without interruptions', '', '– Japanese proverb'],
      \ ['A language that doesn’t affect the way you think about programming is not worth knowing.', '- Alan Perlis'],
      \ ['Bad programmers worry about the code. Good programmers worry about data structures and their relationships', '' , '— Linus Torvalds'],
      \ ['Work expands to fill the time available for its completion.', '', "— C. Northcote Parkinson (Parkinson's Law)"],
      \ ['Hard Choices, Easy Life. Easy Choices, Hard Life.', '', '— Jerzy Gregory'],
      \ ['Future regret minimization is a powerful force for good judgement.', '', '— Tobi Lutke'],
      \ ['The works must be conceived with fire in the soul but executed with clinical coolness', '', '— Joan Miró'],
      \ ['Believe those who seek the truth, doubt those who find it.', '', '— André Gide'],
      \ ["Argue like you're right. Listen like you're wrong", '', '— Adam M. Grant'],
      \ ['Luck is what happens when preparation meets opportunity.', '', '— Seneca'],
      \ ['A complex system that works is invariably found to have evolved from a simple system that worked. The inverse proposition also appears to be true: A complex system designed from scratch never works and cannot be made to work. You have to start over, beginning with a working simple system.', '', '— John Gall'],
      \ ['I call it my billion-dollar mistake. It was the invention of the null reference in 1965. At that time, I was designing the first comprehensive type system for references in an object oriented language. My goal was to ensure that all use of references should be absolutely safe, with checking performed automatically by the compiler. But I couldn’t resist the temptation to put in a null reference, simply because it was so easy to implement. This has led to innumerable errors, vulnerabilities, and system crashes, which have probably caused a billion dollars of pain and damage in the last forty years.', '', '— Tony Hoare, the inventor of Null References'],
      \ ['I think that large objected-oriented programs struggle with increasing complexity as you build this large object graph of mutable objects. You know, trying to understand and keep in your mind what will happen when you call a method and what will the side effects be.', '', '— Rich Hickey'],
      \ ['Most people overestimate what they can do in one year and underestimate what they can do in ten years', '', '— Bill Gates'],
      \ ['Compound interest is the eighth wonder of the world. He who understands it, earns it. He who doesn’t, pays it.', '', '— Albert Einstein'],
      \ ['Time is the fire in which we burn', '', '— Delmore Schwartz'],
      \ ['A ship in harbor is safe, but that is not what ships are built for.', '— John A. Shedd'],
      \ ['You can’t call yourself a leader by coming into a situation that is by nature uncertain, ambiguous — and create confusion.', 'You have to create clarity where none exists', '— Satya Nadella'],
      \ ['The competent programmer is fully aware of the strictly limited size of his own skull; therefore he approaches the programming task in full humility', '— Edsger W. Dijkstra']
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
      \ { 'header': ['   MRU [' . fnamemodify(getcwd(), ':~') . ']'], 'type': 'dir' },
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
