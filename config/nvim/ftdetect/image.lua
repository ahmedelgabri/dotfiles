local au = require '_.utils.au'

au.autocmd {
	event = { 'BufRead', 'BufNewFile' },
	pattern = '*.jpg,*.png,*.gif,*.jpeg',
	command = [[set filetype=image]],
}
