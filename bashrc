#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias upcdown='rclone copy upc:/assig ~/assig/ --drive-acknowledge-abuse -P'
alias upcup='rclone copy ~/assig/ upc:/assig/ --drive-acknowledge-abuse -P'
alias upcsync='upcdown && upcup' 
alias ls='ls --color=auto -la'
alias ip='ip -c'
alias swayconf='nvim ~/.config/sway/config'
alias nixrebuild='sudo nixos-rebuild switch -I nixos-config=configuration.nix'
alias codium='codium --ozone-platform-hint=auto'
#PS1='[\u@\h \W]\$ '
eval "$(starship init bash)"
