#!/bin/bash

# User to permission and customize
ME="ssokolow"

# Only prompt for a password once so this can be left unattended
if [ "$(id -u)" -ne 0 ]; then
    echo "Re-running self as root..."
    exec sudo "$0" "$@"
fi

# Do this once up here to keep paths simple
cd "$(dirname "$0")"

# Get $HOME for $ME
HOMEDIR="$( getent passwd "$ME" | cut -d: -f6 )"

# Make sure apt-get doesn't pause to prompt for input
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

APT_RELEASE="$(lsb_release -cs)"

echo " * Enabling multiarch"
dpkg --add-architecture i386

echo " * Enabling external package sources"

add-apt-repository -y ppa:nilarimogard/webupd8 # (for up-to-date Audacious)
add-apt-repository -y ppa:ubuntu-mozilla-daily/firefox-aurora # (for up-to-date Firefox)
add-apt-repository -y ppa:ubuntu-wine/ppa # (for up-to-date Wine)
add-apt-repository -y ppa:chris-lea/node.js # (for up-to-date Node.js)
add-apt-repository -y ppa:anay/ppa # (http://docs.travis-ci.com/user/cc-menu/ )
add-apt-repository -y ppa:makson96/desurium-stable
add-apt-repository -y ppa:cdemu/ppa
add-apt-repository -y ppa:jd-team/jdownloader
add-apt-repository -y ppa:nilarimogard/webupd8 # LGOGDownloader
add-apt-repository -y ppa:richardgv/compton
add-apt-repository -y ppa:glennric/dolphin-emu
add-apt-repository -y ppa:fkrull/deadsnakes # Various Python version for tox
add-apt-repository -y ppa:pypy/ppa # ...and PyPy for tox
add-apt-repository -y ppa:gottcode/gcppa # FocusWriter
add-apt-repository -y ppa:ryochan7/antimicro
add-apt-repository ppa:zeal-developers/ppa

if [ "$(hostname)" = "monolith" -a "$(lsb_release -sr)" = "14.04" ]; then
    echo " * Adding updated nvidia-331 source to bypass *buntu 14.04 bug"
    add-apt-repository -y ppa:xorg-edgers/ppa
fi

echo " ... BasKet (TDE)"

# BasKet (http://www.trinitydesktop.org/installation.php#ubuntu)
# TODO: Figure out how to make this reliably up-to-date when Trinity sometimes lags behind
add-apt-repository -y "deb http://ppa.quickbuild.pearsoncomputing.net/trinity/trinity-nightly-builds/ubuntu ${APT_RELEASE} main"
add-apt-repository -y "deb http://ppa.quickbuild.pearsoncomputing.net/trinity/trinity-nightly-build-dependencies/ubuntu ${APT_RELEASE} main"
apt-key adv --keyserver keyserver.quickbuild.pearsoncomputing.net --recv-keys F5CFC95C

echo " ... eawpatches"
add-apt-repository -y 'deb http://www.fbriere.net/debian stable misc'
wget -O- http://www.fbriere.net/public_key.html | apt-key add -

# Update the package cache to include the newly-added repos
echo " * Updating the package cache"
apt-get update -y

echo " * Purging undesired Lubuntu and Ubuntu stuff"
apt-get purge sylpheed ace-of-penguins gnumeric gnumeric-common mtpaint modemmanager transmission transmission-gtk transmission-common appmenu-gtk3 appmenu-gtk appmenu-qt indicator-applet-appmenu indicator-appmenu liboverlay-scrollbar unity-gtk2-module unity-gtk3-module light-locker gpicview gnome-exe-thumbnailer -y

if [ "$(lsb_release -sr)" == "14.04" ]; then
    echo " * Removing iBus to unbreak Chromium"
    apt-get purge ibus -y

    echo " * Removing GUI update notifier in favour of one that doesn't nag"
    # ...because LXSession is too broken to let me disable it
    apt-get autoremove update-notifier -y
else
    echo "TODO: Test iBus with Chromium and remove this code."
    echo "TODO: Text whether LXSession's autostart disabling is fixed."
fi

echo " * Updating remaining packages"
apt-get dist-upgrade -y

#TODO: Identify all of the GTK+ 3.x apps on my system and find GTK+ 2.x
#      alternatives so I don't have to deal with the GTK+ 3.x version of the
#      Places sidebar in the Open/Save dialogs.
echo " * Installing base set of desired Debian/Ubuntu packages"
(egrep -v '^#' - | xargs apt-get install -y) << EOF

# Still need to be installed in Porteus:
ack-grep
chromium-browser
colordiff
nautilus-dropbox
fortune-mod
gaffitter
gmrun
jdownloader
keepass2
mercurial
ncdu
nodejs
pidgin-bot-sentry
pychecker
pylint
python-nose
python-notify
python-pip
python-tidylib
python-tz
python-virtualenv
python3-unidecode
python3-yaml
rxvt-unicode
sqlite3
sqliteman
tellico
thunderbird
tig
winpdb
xclip
xournal
xpad
youtube-dl
zeal

# Note: python-tidylib must be here so it can pull in tidylib for virtualenvs
# which install their own copies of PyTidyLib.

# Already in my Porteus or not necessary:
advancecomp
apache2
apt-file
aptitude
ark
audacious
comix
curl
festival
filelight
firefox
git
git-gui
gksu
gpm
geeqie
htop
incron
jpegoptim
k3b
konqueror
konq-plugins
mc
openssh-server
optipng
p7zip-full
p7zip-rar
parcellite
pinfo
pngcrush
postgresql
pv
pydf
python-gtk2
python-imaging
python-lxml
rdiff-backup
rss-glx
timidity
unrar
veromix
vim-doc
vim-gtk
virtualbox
virtualbox-guest-additions-iso
xchat
xscreensaver
xscreensaver-gl
xscreensaver-screensaver-bsod
zsh
zsh-doc

# May exclude from Porteus:
antimicro
arduino
arduino-mk
bottlerocket
calibre
compton
conky-all
desurium
dhex
dosbox
evince
ruby
gimp
haskell-platform
hddtemp
inkscape
iotop
ipython
ipython3
ipython-doc
ipython-notebook
ipython-qtconsole
ipython3-qtconsole
latencytop
libreoffice
libreoffice-nlpsolver
libreoffice-ogltrans
libreoffice-pdfimport
libreoffice-presenter-console
libreoffice-presentation-minimizer
libreoffice-wiki-publisher
libreoffice-writer2latex
libreoffice-writer2xhtml
lirc
lua5.2
lyx
mutt
nitrogen
numlockx
okular
opensp
php-codesniffer
playonlinux
python-buildnotify
python-examples
python-psutil
python3
python3-doc
python3-examples
python3-setuptools
qt4-dev-tools
redshift
redshift-gtk
samba
stunnel
texlive-xetex
timelimit
uptimed
wxhexeditor
xsane

# Porteus Status Unknown:
aosd-cat
checkinstall
chm2pdf
cifs-utils
deluge-gtk
elementary-icon-theme
expect
fuseiso
graphviz
irssi
kdiff3
libnotify-bin
links
links2
libpurple-bin
lm-sensors
lynx
mencoder
mpv
normalize-audio
pidgin
pidgin-otr
pidgin-plugin-pack
python-dbus
python-dev
python-epydoc
python-libtorrent
python-setuptools
python-wnck
python-xlib
python-xpyb
screen
scrot
ssh-askpass-gnome
smartmontools
smem
sox
sshfs
synergy
task
units
wdiff
wmctrl
xautomation
xbindkeys
xchm
xdotool

# For programming in vala
gdb
valac
valadoc
libgtk-3-dev
libgee-dev

EOF

# Install PyUSB for Python 3.x
pip3 install pyusb --pre

# Set up lirc
mkdir -p /etc/lirc
cp -n etc/lirc/* /etc/lirc/

# Set up planetfilter
# http://feeding.cloud.geek.nz/posts/keeping-up-with-noisy-blog-aggregators-using-planetfilter/
apt-get install planetfilter
cp -n etc/planetfilter.d/* /etc/planetfilter.d/
/usr/share/planetfilter/update-feeds
# ...via apache so Thunderbird won't shun it for being file://
cp etc/apache2/sites-available/100-planetfilter.conf /etc/apache2/sites-available/100-planetfilter.conf
a2ensite 100-planetfilter
service apache2 reload

# Now that dependencies have been pulled in...
echo " * Downgrading Geeqie to a working version"
dpkg -i supplemental/geeqie_1.0/*.deb
echo "geeqie hold" | dpkg --set-selections
apt-get install -f

if [ "$(lsb_release -sr)" == "14.04" ]; then
    echo " * Installing zsh manpages to work around idiot Ubuntu maintainers"
    cp supplemental/zsh_manpages/*.1 /usr/share/man/man1/
else
    echo "TODO: Check whether I still need to install zsh manpages manually."
fi

# Set up LCDproc for the case LCD if I'm running on monolith
if [ "$(hostname)" = "monolith" ]; then
    echo " * Enabling hddtemp daemon"
    sed -i 's@^RUN_DAEMON="\(false\|no\)"$@RUN_DAEMON="true"@' /etc/default/hddtemp

    echo " * Setting up lcdproc for monolith"
    apt-get install -y lcdproc
    cp etc/LCDd.conf etc/lcdproc.conf /etc/
    /etc/init.d/LCDd restart

    #TODO: Set up lcdproc to run on boot via /etc/rc.local on monolith
    #      rather than on login.

    echo " * Setting up TrueRNG entropy source for monolith"
    apt-get install -y rng-tools
    cp etc/udev/rules.d/99-TrueRNG.rules /etc/udev/rules.d/
    cp etc/default/rng-tools /etc/default/rng-tools
    update-rc.d rng-tools defaults

    echo " * Setting up NES controller adapter fix for udev"
    cp etc/udev/rules.d/99-nes-controller.rules /etc/udev/rules.d/

    echo " * Setting up SpaceNavD for my 3D mouse on monolith"
    apt-get install -y spacenavd
    cp etc/spnavrc /etc/
    /etc/init.d/spacenavd restart

    echo " * Setting up Samba shares for monolith"
    addgroup family
    cp etc/samba/smb.conf /etc/samba/smb.conf
    for NICK in beverly andre nicky; do
        useradd "$NICK"
        gpasswd "$NICK" family
    done
    gpasswd "$ME" family

    echo " * Setting up SFTP chroot for file exchange with Nostalgia PCs"
    apt-get install -y rssh
    useradd -m nostalgia-exchange
    chown root:root ~nostalgia-exchange
    mkdir ~nostalgia-exchange/writable
    chown nostalgia-exchange:ssokolow ~nostalgia-exchange/writable
    chmod 775 ~nostalgia-exchange/writable
    chmod +s ~nostalgia-exchange/writable
    mkdir ~nostalgia-exchange/.ssh
    chown nostalgia-exchange:nostalgia-exchange ~nostalgia-exchange/.ssh
    chmod 700 ~nostalgia-exchange/.ssh
    chsh -s /usr/bin/rssh nostalgia-exchange
    mkdir /etc/ssh/authorized_keys/

    echo " * Enabling UDP rsyslog reception for m0n0wall"
    # shellcheck disable=SC2016
    sed -i 's@#$ModLoad imudp@$ModLoad imudp@' /etc/rsyslog.conf
    # shellcheck disable=SC2016
    sed -i 's@#$UDPServerRun 514@$UDPServerRun 514@' /etc/rsyslog.conf

    echo " * Setting up munin for monolith"
    apt-get install -y munin munin-plugins-extra snmp
    #TODO: Add nvclock once it no longer segfaults

    # Set up master config
    cp etc/munin/munin.conf /etc/munin/

    # Set up node plugins
    rm /etc/munin/plugins/*
    ln -s /usr/share/munin/plugins/apache_accesses /etc/munin/plugins/apache_accesses
    ln -s /usr/share/munin/plugins/apache_volume /etc/munin/plugins/apache_volume
    ln -s /usr/share/munin/plugins/cpu /etc/munin/plugins/cpu
    ln -s /usr/share/munin/plugins/cpuspeed /etc/munin/plugins/cpuspeed
    ln -s /usr/share/munin/plugins/df /etc/munin/plugins/df
    ln -s /usr/share/munin/plugins/diskstats /etc/munin/plugins/diskstats
    ln -s /usr/share/munin/plugins/entropy /etc/munin/plugins/entropy
    ln -s /usr/share/munin/plugins/forks /etc/munin/plugins/forks
    ln -s /usr/share/munin/plugins/fw_conntrack /etc/munin/plugins/fw_conntrack
    ln -s /usr/share/munin/plugins/hddtemp_smartctl /etc/munin/plugins/hddtemp_smartctl
    ln -s /usr/share/munin/plugins/http_loadtime /etc/munin/plugins/http_loadtime
    ln -s /usr/share/munin/plugins/if_err_ /etc/munin/plugins/if_err_eth0
    ln -s /usr/share/munin/plugins/if_ /etc/munin/plugins/if_eth0
    ln -s /usr/share/munin/plugins/iostat /etc/munin/plugins/iostat
    ln -s /usr/share/munin/plugins/iostat_ios /etc/munin/plugins/iostat_ios
    ln -s /usr/share/munin/plugins/load /etc/munin/plugins/load
    ln -s /usr/share/munin/plugins/memory /etc/munin/plugins/memory
    ln -s /usr/share/munin/plugins/munin_stats /etc/munin/plugins/munin_stats
    ln -s /usr/share/munin/plugins/nvidia_ /etc/munin/plugins/nvidia_clock
    ln -s /usr/share/munin/plugins/nvidia_ /etc/munin/plugins/nvidia_temp
    ln -s /usr/share/munin/plugins/nvidia_ /etc/munin/plugins/nvidia_volt
    ln -s /usr/share/munin/plugins/processes /etc/munin/plugins/processes
    ln -s /usr/share/munin/plugins/proc_pri /etc/munin/plugins/proc_pri
    ln -s /usr/share/munin/plugins/smart_ /etc/munin/plugins/smart_sda
    ln -s /usr/share/munin/plugins/smart_ /etc/munin/plugins/smart_sdb
    ln -s /usr/share/munin/plugins/smart_ /etc/munin/plugins/smart_sdc
    ln -s /usr/share/munin/plugins/snmp__if_ /etc/munin/plugins/snmp_router_if_1
    ln -s /usr/share/munin/plugins/snmp__if_ /etc/munin/plugins/snmp_router_if_2
    ln -s /usr/share/munin/plugins/snmp__if_ /etc/munin/plugins/snmp_router_if_3
    ln -s /usr/share/munin/plugins/snmp__if_ /etc/munin/plugins/snmp_router_if_7
    ln -s /usr/share/munin/plugins/snmp__if_multi /etc/munin/plugins/snmp_router_if_multi
    ln -s /usr/share/munin/plugins/snmp__uptime /etc/munin/plugins/snmp_router_uptime
    ln -s /usr/share/munin/plugins/swap /etc/munin/plugins/swap
    ln -s /usr/share/munin/plugins/uptime /etc/munin/plugins/uptime
    ln -s /usr/share/munin/plugins/vmstat /etc/munin/plugins/vmstat

    # Allow only loopback connections to the local munin node
    sed -i -e 's@\(^host \*$\)@# \1@' -e 's@^# \(host 127.0.0.1\)@\1@' /etc/munin/munin-node.conf
    /etc/init.d/munin-node restart

    echo " * Setting up nVidia drivers for monolith"
    apt-get install -y nvidia-current nvidia-settings
    chattr -i /etc/X11/xorg.conf
    cp etc/X11/xorg.conf /etc/X11/
    chattr +i /etc/X11/xorg.conf
    if [ "$(lsb_release -sr)" = "14.04" ]; then
        echo " * Updating nvidia-drivers to bypass *buntu 14.04 bug"
        apt-get install nvidia-346 -y
    fi

    echo " * Setting up deferred nVidia driver updates"
    cp supplemental/update_nvidia.py /usr/local/sbin
    chmod +x /usr/local/sbin/update_nvidia.py
    cp etc/init/update_nvidia.conf /etc/init/

    # Let it figure out which packages to hold
    /usr/local/sbin/update_nvidia.py

    echo " * Adding tsched=0 to PulseAudio config for proper function"
    sed -i 's/^\(load-module module-udev-detect\)\s*$/\1 tsched=0/' /etc/pulse/default.pa

    echo " * Downloading WinTV-HVR 1600 firmware (can't hurt, may help)"
    pushd /lib/firmware
    for X in v4l-cx23418-cpu.fw v4l-cx23418-apu.fw v4l-cx23418-dig.fw; do
        if [ ! -e "$X" ]; then
            echo " ... $X"
            wget http://linuxtv.org/downloads/firmware/"$X"
        fi
    done
    popd

    if grep 'echo 1 > /proc/sys/abi/ldt16' /etc/rc.local; then
        echo " * 16-bit segments already allowed"
    else
        echo " * Re-allowing 16-bit segments. Gotta have my BrickLayer."
        sed -i 's@exit 0@echo 1 > /proc/sys/abi/ldt16\nexit 0@' /etc/rc.local
    fi
fi

echo " * Ensuring a verbose (debug-friendly), non-splash Linux boot process"
sed -i 's@GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"@GRUB_CMDLINE_LINUX_DEFAULT="verbose"@' /etc/default/grub
update-grub

# TODO: How do I specify that only the X newest kernels should be kept?

echo " * Removing 'Floppy Drive' from Places menu"
rm -rf /media/floppy*
echo "blacklist floppy" | tee /etc/modprobe.d/blacklist-floppy.conf
rmmod floppy
update-initramfs -u

# Separate out stuff only found in alternate repos to avoid problems if the
# apt-get update fails
echo " * Setting packages from 3rd-party repos"
# TODO: Figure out how to rework this to prevent Wine from mucking around in my launcher
apt-get install -y wine
apt-get install -y --no-install-recommends basket-trinity
apt-get install -y eawpatches
apt-get install -y cdemu-daemon cdemu-client gcdemu
apt-get install -y lgogdownloader
apt-get install -y dolphin-emu || apt-get install -y dolphin-emu-master
apt-get install -y python{2.6,3.1,3.2,3.3}-complete # ...for tox
apt-get install -y pypy # ...for tox
apt-get install -y focuswriter
cp etc/udev/rules.d/49-teensy.rules /etc/udev/rules.d/
cp etc/udev/rules.d/99-escpos.rules /etc/udev/rules.d/

# Source: https://lwn.net/Articles/616241/
echo "* Limiting this machine's effect on bufferbloat"
cp etc/sysctl.d/99-bufferbloat.conf /etc/sysctl.d/

echo " * Overwriting gcdemu tray icon since it ignores my icon theme"
cp home/.local/share/icons/hicolor/scalable/apps/gcdemu-icon.svg /usr/share/icons/hicolor/scalable/apps/gcdemu-icon.svg

#echo " * Removing pulseaudio for pegging one of my CPU cores when I game"
#apt-get purge pulseaudio.* gst.*-pulseaudio -y
#apt-get autoremove -y
#echo "pulseaudio hold" | dpkg --set-selections

echo " * Using pip to install python packages not covered by apt-get"
pip install --upgrade -r requirements.txt

echo " * Installing npm and node packages"
curl http://npmjs.org/install.sh | sh
xargs npm install -g << EOF
coffee-script
docco
jshint
jsonlint
nodemon
svgo
uglify-js
coffeelint
EOF

echo " * Installing ruby gems"
gem install jekyll travis-lint

echo " * Setting up ad-blocking hosts file"
wget http://ssokolow.com/scripts/upd_hosts.py -O /etc/cron.monthly/upd_hosts.py
chmod +x /etc/cron.monthly/upd_hosts.py
/etc/cron.monthly/upd_hosts.py

echo " * Cursing VirtualBox devs for not allowing snapshot CD image paths to be edited"
ln -s virtualbox /usr/share/virtualbox-ose

echo " * Linking in KeePass2 Plugins"
ln -s "$HOMEDIR"/.profile_repo/supplemental/keepass2_plugins/ /usr/lib/keepass2/plugins

echo " * Restoring backup crontab for $ME"
crontab supplemental/crontab_backup

echo " * Making update_check.sh passwordless"
cp etc/sudoers/update_checker /etc/sudoers/update_checker

if [ ! -e /etc/sensors3.conf ]; then
    echo " * Setting up sensors"
    yes | sensors-detect
else
    echo " * Sensors already set up. Skipping."
fi

if [ -e /etc/incron.allow ]; then
    echo " * Ensuring '$ME' is permitted to use incron"
    grep -Fx "$ME" /etc/incron.allow || echo "$ME" >> /etc/incron.allow
fi

echo " * Setting up eawpatches in Timidity"
if [ -e /etc/timidity/eawpatches.cfg ]; then
    if egrep -q '^source /etc/timidity/freepats.cfg$' /etc/timidity/timidity.cfg; then
        sed -i 's@\(^source /etc/timidity/freepats.cfg$\)@#\1\nsource /etc/timidity/eawpatches.cfg@' /etc/timidity/timidity.cfg
    else
        echo " * Default Timidity patch set isn't freepats. Skipping."
    fi
else
    echo " * WARNING: Installation of eawpatches for timidity appears to have FAILED\!"
fi

if [ -e /bin/zsh ]; then
    echo " * Setting login shell to zsh..."
    chsh -s /bin/zsh "$ME"
fi

echo " * Adding '$ME' to requisite groups"
for GRP in tty dialout video lpadmin vboxusers family; do
    gpasswd -a "$ME" "$GRP"
done

if [ -e /srv/inbound ]; then
    echo " * Found /srv/inbound. Setting permissions."
    chown -R "$ME:family" /srv/inbound
    find /srv/inbound -type d -exec chmod 2775 {} \;
    find /srv/inbound -type f -exec chmod a-x {} \;
else
    echo " * No /srv/inbound found. Skipping permissions fix."
fi

echo " * Setting up basic firewall"
cp -n etc/ufw/applications.d/* /etc/ufw/applications.d/
cp etc/cron.daily/ensure_ufw /etc/cron.daily/
chmod +x /etc/cron.daily/ensure_ufw
ufw enable
for X in OpenSSH VNC Deluge Dropbox Samba avahi-daemon dhclient ntpd pidgin synergy; do
    ufw allow "$X"
done

function add_polconf_postprefixcreate() {
    polconf_dir="$2"/.PlayOnLinux/configurations/
    ppfix_path="$polconf_dir"/post_prefixcreate

    if [ -e "$ppfix_path" ]; then
        echo "Skipping. Already exists: $ppfix_path"
        return
    fi

    me_group="$( getent passwd "$1" | cut -d: -f1 )"

    mkdir -p "$polconf_dir"
    echo "POL_Call POL_Install_PrivateUserDirs" > "$ppfix_path"
    chown -R "$1:$me_group" "$polconf_dir"
}
echo " * Setting up 'winetricks sandbox'-like PlayOnLinux behaviour"
add_polconf_postprefixcreate "$ME" "$HOMEDIR"
sudo -u "$ME" supplemental/configure_pol.sh

if pgrep lxpanel >/dev/null; then
    echo " * Restarting lxpanel to acknowledge new launchers"
    lxpanelctl restart
fi

if [ "$1" == "--upgrade" ]; then
    echo " * Upgrading Python virtualenvs"
    find . -maxdepth 1 -type d -exec virtualenv -p "$(which python)" {} \;
else
    echo "IMPORTANT: If upgrading, please re-run this script with --upgrade"
fi

echo "IMPORTANT: Don't forget to..."
echo " - verify that all automated backup mechanisms got set up correctly."
echo " - edit /etc/ssh/sshd_config to allow only non-root, pubkey authentication."
echo " - Set up the keypair for ~nostalgia-exchange"
echo "   ( http://www.gentoo.org/doc/en/security/security-handbook.xml?part=1&chap=10#doc_chap11 )"
echo " - re-run 'smbpasswd -a' for all permissioned users"
echo " - run vim once and then build the compiled part of YouCompleteMe"
echo " - reinstall lap."
echo " - reinstall hub (https://github.com/github/hub)."
echo " - reinstall the fonts from https://github.com/Lokaltog/powerline-fonts"
echo " - run 'dpkg-reconfigure -a -u'"
echo " - Run 'POL_Config_Write NO_DESKTOP_ICON \"TRUE\"' in the POL console"
echo " - Add "/mnt/incoming/.backups /srv/backups /mnt/buffalo_ext/backups" to /etc/updatedb.conf and uncomment PRUNENAMES."
echo " - Re-extract the EasyCap somagic firmware from the driver disk."
echo " - cabal install pandoc pandoc-citeproc"
# TODO: Find a way to ask just the dpkg-reconfigure questions which were
#       skipped by the noninteractive frontend.
# TODO: Drop back to unprivileged operation after this runs and force a run
#       of kbuildsycoca4.
