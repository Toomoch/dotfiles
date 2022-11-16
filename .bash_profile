#
# ~/.bash_profile
#
export MOZ_ENABLE_WAYLAND=1
[[ -f ~/.bashrc ]] && . ~/.bashrc
# If running from tty1 start sway
[ "$(tty)" = "/dev/tty1" ] && exec sway
