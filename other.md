### Allow ddcutil to run without su priviledges (for use in polybar)

Add the following to sudoers file:

    # Allow myself to run ddcutil wthout sudo to use it in polybar
    jantari AMDSESKTOP = (root) NOPASSWD: /usr/bin/ddcutil


