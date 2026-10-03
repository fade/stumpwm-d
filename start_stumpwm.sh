#!/bin/bash
#-*- mode: shell -*-
# set -x

#=============================================================================
# GENERAL INITIALIZATION
#=============================================================================


# Identify the home of our gtkrc file, important for setting styles of 
# gtk-based applications
# export GTK2_RC_FILES="$HOME/.gtkrc-2.0"

# Load X resources (fixes some font issues)
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

# Start compositing to support transparency. You can omit this
# if you prefer not to use any transparency, but it is likely to cause
# ugly black fringing with some programs such as synapse that expect
# transparency support.

# compositing for various transparency effects. picom supersedes compton.
command -v picom >/dev/null && picom &

#=============================================================================
# SCREEN CONFIGURATION
#=============================================================================


# Each machine has its own monitors, so the xrandr setup is chosen by
# host name. Run xrandr with no arguments to list a machine's outputs.
# A host with no entry here keeps whatever layout X chose at startup.

case "$(uname -n)" in
    ghost)
        # The DVI monitor is primary; the HDMI monitor, when connected,
        # sits to its left.
        xrandr --output DVI-D-0 --auto --primary
        if xrandr | grep -q '^HDMI-0 connected'; then
            xrandr --output HDMI-0 --auto --left-of DVI-D-0
        fi
        sleep 1
        ;;
    bb8)
        # The built-in panel, with any external monitor mirrored until
        # it is arranged by hand.
        xrandr --auto
        ;;
esac

#=============================================================================
# LAPTOP KEYBOARD
#=============================================================================

# My desktop keyboard is programmable and already puts Control on Caps
# Lock and swaps the square brackets with the parens on 9 and 0. A
# laptop's built-in keyboard needs the same changes made in software.
# They go on the built-in keyboard only: anything plugged in keeps its
# own layout, so the programmable keyboard is never remapped twice.
#
# With the swap, the [ and ] keys type ( and ), shifted 9 and 0 type
# [ and ], and the braces stay where they were.
#
# Caps Lock is always Control, so Ctrl+Shift shortcuts work with either
# Shift key, and pressing both Shift keys together toggles Caps Lock.

LAPTOP_KEYBOARD="AT Translated Set 2 keyboard"

laptop_keyboard_id=$(xinput list --id-only "keyboard:$LAPTOP_KEYBOARD" 2>/dev/null)
if [ -n "$laptop_keyboard_id" ]; then
    xkb_dir=$(mktemp -d)
    mkdir -p "$xkb_dir/symbols"
    cat > "$xkb_dir/symbols/lisp" <<'EOF'
xkb_symbols "parens" {
    key <AE09> { [ 9,          bracketleft  ] };
    key <AE10> { [ 0,          bracketright ] };
    key <AD11> { [ parenleft,  braceleft    ] };
    key <AD12> { [ parenright, braceright   ] };
};
EOF
    setxkbmap -device "$laptop_keyboard_id" -option "" -option ctrl:nocaps -option shift:both_capslock -print \
        | sed '/xkb_symbols/s/"\([^"]*\)"/"\1+lisp(parens)"/' \
        | xkbcomp -w 0 -I"$xkb_dir" -i "$laptop_keyboard_id" - "$DISPLAY"
    rm -rf "$xkb_dir"
fi

#=============================================================================
# STARTUP ICON TRAY
#=============================================================================

# We are using stalonetray to create a small icon tray at the
# top right of the screen. You are likely to want to tweak the
# size of the icons and the width of the tray based upon the
# size of your screen and your xmobar configuration. The goal is
# to make stalonetray look like it is part of xmobar.
# 
# Line by line, the options used by default below mean:
# - icons should be aligned with the "East" or right side of the tray
# - the width of the tray should be 5 icons wide by one icon tall, and it 
#   should be located 0 pixels from the right of the screen (-0) and 0 pixels
#   from the top of the screen (+0).
# - By setting our maximum geometry to the same thing, the tray will not grow.
# - The background color of the tray should be black.
# - This program should not show up in any taskbar.
# - Icons should be set to size "24".
# - Kludges argument of "force_icons_size" forces all icons to really, truly 
#   be the size we set.
# - window-strut "none" means windows are allowed to cover the tray. In
#   other words, trust xmonad to handle this part.
#
# stalonetray --icon-gravity E \
#             --geometry 9x1-0+0 \
#             --max-geometry 9x1-0+0 \
#             --background '#1f1f1f' \
#             --skip-taskbar \
#             --icon-size 24 \
#             --kludges force_icons_size \
#     &



# Run the gnome-keyring-daemon to avoid issues you otherwise may encounter
# when using gnome applications which expect access to the keyring, such
# as Empathy. This prevents prompts you may otherwise get for invalid
# certificates and the like.
# gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh


# Synaptics
# syndaemon -i 1 -t &

#Plz low screen brightness
# xbacklight -set 50

#=============================================================================
# KDE APPLICATION SUPPORT
#=============================================================================

# KDE applications run well outside Plasma once they can find the
# services Plasma would otherwise provide. KDE 6 dropped kdeinit, and
# nothing replaces it: applications start their helpers themselves and
# D-Bus starts KDE's daemons on demand. What is left is telling them
# they are on KDE and starting the few helpers Plasma's autostart would.

if command -v kbuildsycoca6 >/dev/null; then
    # Use the KDE look, file dialogs, desktop portal and application
    # menu, so "Open With" lists your applications.
    export XDG_CURRENT_DESKTOP=KDE
    export KDE_SESSION_VERSION=6
    export XDG_MENU_PREFIX=plasma-

    # A Plasma Wayland session can leave its settings behind in the
    # systemd user manager. Without this, applications that D-Bus or
    # systemd starts would look for a Wayland display that is gone.
    systemctl --user unset-environment WAYLAND_DISPLAY KDE_FULL_SESSION         KDE_APPLICATIONS_AS_SCOPE QT_WAYLAND_RECONNECT
    dbus-update-activation-environment --systemd DISPLAY XAUTHORITY         XDG_CURRENT_DESKTOP KDE_SESSION_VERSION XDG_MENU_PREFIX XDG_SESSION_TYPE

    # Refresh KDE's record of installed applications and file types.
    kbuildsycoca6 >/dev/null 2>&1 &

    # Unlock the wallet with the login password, so applications do not
    # ask for it again.
    [ -x /usr/lib/pam_kwallet_init ] && /usr/lib/pam_kwallet_init &

    # Let applications ask for an administrator password when they need
    # one, as System Settings and Partition Manager do.
    systemctl --user start plasma-polkit-agent.service
fi

# Now, finally, start stumpWM
exec /usr/local/bin/stumpwm
