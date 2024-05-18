local au = require '_.utils.au'

au.autocmd {
	event = { 'BufRead', 'BufNewFile' },
	pattern = '*.mp3,*.flac,*.wav,*.ogg',
	command = [[set filetype=audio]],
}
