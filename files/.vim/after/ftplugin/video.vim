call system('mpv --geometry=50%+50%+50% ' . shellescape(expand('%:p')) . ' &>/dev/null &') | buffer# | bdelete# | redraw! | syntax on
