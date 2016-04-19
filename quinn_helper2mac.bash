#!bin/bash

set -u
set -e

myname=$LOGNAME

function show_title {
echo ""
echo "================"
echo "=$1"
echo "================"
echo ""
}

#############################
show_title "Configure shell color"

grep -q 'CLICOLOR' ~/.bash_profile || {
echo -n '
# Configure shell color
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

' >> ~/.bash_profile
}

#############################
show_title "configure vim"

grep -q 'quinn' ~/.vimrc || {
echo -n '
" Added by quinn
syntax on
set hlsearch
set incsearc
set autoindent
set tabstop=4
filetype indent on
' >> ~/.vimrc
}

###########################
show_title "add aliases and fuction"

grep -q 'alias la' ~/.bash_profile || {
echo -n '
# add aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias /='cd /'
alias dh='df -h'
alias ll='ls -l'
alias la='ls -a'
alias rr='rm -r'
' >> ~/.bash_profile
}
