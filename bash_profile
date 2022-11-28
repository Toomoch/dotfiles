#
# ~/.bash_profile
#
export XDG_CURRENT_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORMTHEME=qt5ct
[[ -f ~/.bashrc ]] && . ~/.bashrc
# If running from tty1 start sway
[ "$(tty)" = "/dev/tty1" ] && exec sway
