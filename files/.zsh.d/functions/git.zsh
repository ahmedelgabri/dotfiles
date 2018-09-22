# Git functions
git_since(){
  git lg --since=$@
}

git_until(){
  git lg --until=$@
}

git_author(){
  git lg --author="$@"
}

git_grep(){
  git lg --grep="$@"
}

gitwork(){
    git config user.email "$1"
}






