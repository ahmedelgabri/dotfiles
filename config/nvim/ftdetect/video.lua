local au = require '_.utils.au'

au.autocmd {
	event = { 'BufRead', 'BufNewFile' },
	pattern = '*.avi,*.mp4,*.mkv,*.mov,*.mpg',
	command = [[set filetype=video]],
}
