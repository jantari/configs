### Allow ddcutil to run without su priviledges (for use in polybar)

Add the following to sudoers file:

    # Allow myself to run ddcutil wthout sudo to use it in polybar
    jantari AMDSESKTOP = (root) NOPASSWD: /usr/bin/ddcutil

### Disable hidden Ctrl+Alt+Tab to switch windows in MATE, Gnome, Cinnamon:

    gsettings set org.mate.Marco.global-keybindings switch-windows-all 'disabled'

### Ansible Rolle Ordnerstruktur:

    ./ROLENAME
        ├── README.md
        ├── defaults
        │   └── main.yml
        ├── files
        │   ├── file1
        │   └── file2
        ├── handlers
        │   └── handler1.yml
        ├── tasks
        │   ├── task1.yml
        │   └── task2.yml
        └── vars
            └── vars.yml
