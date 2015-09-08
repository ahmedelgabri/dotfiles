# make a directory and cd to it
mcd() {
    test -d "$1" || mkdir "$1" && cd "$1"
}
