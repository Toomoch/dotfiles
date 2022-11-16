#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias upcdown='rclone copy upc:/assig ~/assig/ --drive-acknowledge-abuse -P'
alias upcup='rclone copy ~/assig/ upc:/assig/ --drive-acknowledge-abuse -P'
alias ls='ls --color=auto'
alias swayconf='nvim ~/.config/sway/config'
#PS1='[\u@\h \W]\$ '
eval "$(starship init bash)"
