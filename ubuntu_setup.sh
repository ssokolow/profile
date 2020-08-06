#!/bin/bash

# We can't cd until just before handing off to ansible because "$0" may
# be relative to "$PWD" and this script re-calls itself as a subprocess
ansible_prep() {
    shift  # Remove --system from "$@"
    cd "$(dirname "$(readlink -f "$0")")"
}

is_installed() { type "$1" 1>/dev/null 2>&1; return $?; }

# ========================= System-level Installation ========================
if [ "$1" == "--system" ]; then  # System-installation Subprocess Mode
    # Only prompt for a password once so this can be left unattended
    if [ "$(id -u)" -ne 0 ]; then
        # Replace self (the subprocess) with a privileged copy
        echo "Re-running self as root..."
        exec sudo "$0" "$@"
    fi

    # Make sure apt-get doesn't pause to prompt for input
    DEBIAN_FRONTEND=noninteractive
    export DEBIAN_FRONTEND

    # Repair an interrupted apt-get install if present
    apt-get install -f -y

    # Ensure we have an up-to-date ansible
    # TODO: Make this more robust in the presence of dependency conflicts
    if ! is_installed ansible; then
        apt-add-repository -y ppa:ansible/ansible
        apt-get update
    fi

    # Ensure ansible and the dependencies for my playbooks are installed
    apt-get install -y ansible aptitude python-apt python3-apt \
        software-properties-common

    # Let Ansible handle the rest
    ansible_prep
    ansible-playbook ubuntu_system_playbook.yml "$@"

    # Performing deferred package configuration
    # (Kept out of the Ansible playbook because it's interactive and slow)
    # TODO: Figure out the best way to defer this after --user in primary mode
    dpkg --configure --pending

# ========================== User-level Installation =========================
elif [ "$1" == "--user" ]; then  # User-setup Subprocess Mode
    ansible_prep
    ansible-playbook ubuntu_user_playbook.yml "$@"

    # TODO: Adapt this code for updating Python virtualenvs
    # find . -maxdepth 1 -type d -exec virtualenv -p "$(which python)" {} \;

# =========================== Default Run Behaviour ==========================
else  # Primary Mode
    # Run a subprocess of self to set up everything system-level
    "$0" --system "$@"
    "$0" --user "$@"

    # TODO: Handle short args properly
    cd "$(dirname "$(readlink -f "$0")")"
    check_mode=0
    for arg in "$@"; do
        if [ "$arg" = "--check" -o "$arg" = "-C" ]; then
          check_mode=1
        fi
    done
    if [ "$check_mode" = "1" ]; then
        ./install.py --dry-run --diff
    else
        ./install.py
    fi


    if pgrep lxpanel >/dev/null; then
        echo " * Restarting lxpanel to acknowledge new launchers"
        lxpanelctl restart
    fi
    if is_installed kbuildsycoca4; then
        kbuildsycoca4
    fi
fi

# ========================= TODO: CONVERT LINES BELOW ========================

# TODO: Something added group writability to my ~/.zsh. Audit my profile.

echo "IMPORTANT: Don't forget to..."
echo " - edit /etc/ssh/sshd_config to allow only non-root, pubkey authentication."
echo " - Add "/mnt/incoming/.backups /srv/backups /mnt/buffalo_ext/backups" to /etc/updatedb.conf and uncomment PRUNENAMES."
echo " - Run 'sudo update-binfmts --disable cli' after installing Mono so 'cargo test' and 'cargo run' can cross-test"
echo " - reinstall lap."
echo " - reinstall the fonts from https://github.com/Lokaltog/powerline-fonts"
echo " - verify that all automated backup mechanisms got set up correctly."
echo " - reinstall checkmake"
echo " - reinstall munt"
echo " - reinstall whipper (https://github.com/JoeLametta/whipper/)"
echo " - Re-extract the EasyCap somagic firmware from the driver disk."
echo " - re-run 'smbpasswd -a' for all permissioned users"
echo " - verify that stylelint-config-recommended and stylelint got installed"
echo " - Set up /etc/rc.local"
echo " - Set up fan_remote"
echo " - Set up the keypair for ~nostalgia-exchange"
echo "   ( http://www.gentoo.org/doc/en/security/security-handbook.xml?part=1&chap=10#doc_chap11 )"
echo " - Re-setup Firejail"
echo " - Use the 'template' action for anything containing my username"
echo " - Verify that all the system services start correctly after a restart"
echo " - Figure out how to report failed systemd services via e-mail"

#
# TODO: Look into using Vagrant to automatically set up all of my VMs:
# - The Lubuntu ones shouldn't be difficult
# - http://blog.syntaxc4.net/post/2014/09/03/windows-boxes-for-vagrant-courtesy-of-modern-ie.aspx
# - https://www.bram.us/2014/09/24/modern-ie-vagrant-boxes/
# - https://github.com/danielmenezesbr/modernie-winrm
# - https://gist.github.com/andreptb/57e388df5e881937e62a
