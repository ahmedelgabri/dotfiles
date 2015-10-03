function strip_diff_leading_symbols(){
	color_code_regex="(\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K])"
	reset_color="\x1B\[m"
	dim_magenta="\x1B\[38;05;146m"

	# simplify the unified patch diff header
	sed -E "s/^($color_code_regex)diff --git .*$//g" | \
		sed -E "s/^($color_code_regex)index .*$/\n\1$(rule)/g" | \
		sed -E "s/^($color_code_regex)\+\+\+(.*)$/\1+++\5\n\1$(rule)\x1B\[m/g" |\

	# extra color for @@ context line
		sed -E "s/@@$reset_color $reset_color(.*$)/@@ $dim_magenta\1/g"  |\

	# actually strips the leading symbols
		sed -E "s/^($color_code_regex)[\+\-]/\1 /g"
}

## Print a horizontal rule
rule () {
	printf "%$(TERM=xterm-256color tput cols)s\n"|tr " " "-"
}

