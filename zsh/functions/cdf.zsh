# https://github.com/paulirish/dotfiles/blob/f279b2abaa455895c0e9ac6b25500f8c8f8372c6/.functions#L12-L15
# cd into whatever is the forefront Finder window.
function cdf() {  # short for cdfinder
  cd `osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)'`
}
