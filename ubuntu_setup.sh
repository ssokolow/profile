#!/bin/sh

# Only prompt for a password once so this can be left unattended
if [ `id -u` -ne 0 ]; then
    echo "Re-running self as root..."
    exec sudo "$0" "$@"
fi

# Make sure apt-get doesn't pause to prompt for input
DEBIAN_FRONTENT=noninteractive
export DEBIAN_FRONTEND

# The following PPAs and/or external sources must be enabled:
add-apt-repository -y ppa:nilarimogard/webupd8 # (for up-to-date Audacious)
add-apt-repository -y ppa:ubuntu-mozilla-daily/firefox-aurora # (for up-to-date Firefox)
add-apt-repository -y ppa:ubuntu-wine/ppa # (for up-to-date Wine)
add-apt-repository -y ppa:chris-lea/node.js # (for up-to-date Node.js)
add-apt-repository -y ppa:cdemu/ppa
# BasKet (http://www.trinitydesktop.org/installation.php#ubuntu)
# TODO: Figure out how to make this reliably up-to-date when Trinity sometimes lags behind
add-apt-repository -y 'deb http://ppa.quickbuild.pearsoncomputing.net/trinity/trinity-v3.5.13/ubuntu oneiric main'
add-apt-repository -y 'deb http://ppa.quickbuild.pearsoncomputing.net/trinity/trinity-builddeps-v3.5.13/ubuntu oneiric main'
apt-key adv --keyserver keyserver.quickbuild.pearsoncomputing.net --recv-keys 2B8638D0
# Skype
# TODO: Figure out how to make this always use the right release keyword
add-apt-repository -y 'deb http://archive.canonical.com/ubuntu precise partner'
echo foreign-architecture i386 | tee /etc/dpkg/dpkg.cfg.d/multiarch
# eawpatches
add-apt-repository -y 'deb http://www.fbriere.net/debian stable misc'
wget -O- http://www.fbriere.net/public_key.html | sudo apt-key add -
# Opera
if egrep -q '^deb http://deb.opera.com/opera/' /etc/apt/sources.list; then
    echo "Opera source already present."
else
    echo 'deb http://deb.opera.com/opera/ stable non-free' >> /etc/apt/sources.list
    wget -O - http://deb.opera.com/archive.key | sudo apt-key add -
fi

# Stuff Lubuntu installs which I don't want:
apt-get purge sylpheed ace-of-penguins gnumeric mtpaint modemmanager -y
rm /usr/share/applications/gnumeric.desktop

# Stuff Ubuntu installs which I DEFINITELY don't want:
# TODO: What's a cleaner way to say "remove any of the following if installed"?
for X in appmenu-gtk3 appmenu-gtk appmenu-qt indicator-applet-appmenu indicator-appmenu liboverlay-scrollbar;
    do apt-get purge "$X" -y
done

# Update the package cache to include the newly-added repos
apt-get update -y

echo " * Installing base set of desired Debian/Ubuntu packages"
(egrep -v '^#' - | xargs sudo apt-get install -y) << EOF

# Still need to be installed in Porteus:
ack-grep
chromium-browser
colordiff
nautilus-dropbox
fortune-mod
gaffitter
gmrun
mercurial
ncdu
nodejs
nodejs-dev
pychecker
pyflakes
pylint
python-nose
python-notify
python-pip
python-tidylib
python-tz
python-virtualenv
rxvt-unicode
sqlite3
tellico
thunderbird
tig
winpdb
xclip
xpad

# Note: python-tidylib must be here so it can pull in tidylib for virtualenvs
# which install their own copies of PyTidyLib.

# Already in my Porteus or not necessary:
advancecomp
aptitude
audacious
comix
curl
filelight
firefox
git
git-gui
gksu
gpm
gqview
htop
jpegoptim
k3b
konqueror
mc
openssh-server
optipng
p7zip-full
p7zip-rar
parcellite
pinfo
pngcrush
pv
pydf
python-gtk2
python-imaging
python-lxml
timidity
unrar
vim-doc
vim-gtk
virtualbox
virtualbox-guest-additions-iso
xchat
zsh

# May exclude from Porteus:
arduino
arduino-mk
bottlerocket
calibre
conky-all
evince
rubygems
gimp
hddtemp
inkscape
libreoffice
libreoffice-nlpsolver
libreoffice-ogltrans
libreoffice-pdfimport
libreoffice-presenter-console
libreoffice-presentation-minimizer
libreoffice-wiki-publisher
libreoffice-writer2latex
libreoffice-writer2xhtml
lyx
nitrogen
numlockx
okular
opensp
python-psutil
samba
uptimed
xdotool
xsane

# Porteus Status Unknown:
chmsee
kdiff3
graphviz
links
lm-sensors
lynx
normalize-audio
python-dbus
python-setuptools
python-xlib
python-xpyb
screen
ssh-askpass-gnome
smartmontools
sox
sshfs
synergy
pidgin
pidgin-otr
units
wdiff

# For programming in vala
gdb
valac
valadoc
libgtk-3-dev
libgee-dev

EOF

# Separate out stuff only found in alternate repos to avoid problems if the
# apt-get update fails
apt-get install -y wine
apt-get install -y basket-trinity
apt-get install -y eawpatches
apt-get install -y skype
apt-get install -y opera
apt-get install -t cdemu-daemon cdemu-client gcdemu
cp "`dirname \"$0\"`/supplemental/skype /usr/local/bin/"
cp "`dirname \"$0\"`/supplemental/49-teensy.rules /etc/udev/rules.d/"

#TODO: How did one hold a package as uninstalled again?
echo " * Removing pulseaudio for pegging one of my CPU cores when I game"
apt-get purge pulseaudio gstreamer0.10-pulseaudio -y
apt-get autoremove -y

echo " * Using pip to install python packages not covered by apt-get"
pip install -r "`dirname \"$0\"`"/requirements.txt

echo " * Installing npm and node packages"
curl http://npmjs.org/install.sh | sh
xargs npm install -g << EOF
coffee-script
docco
nodemon
uglify-js
EOF

echo " * Installing ruby gems"
gem install jekyll

echo " * Downloading WinTV-HVR 1600 firmware (can't hurt, may help)"
cd /lib/firmware
wget http://linuxtv.org/downloads/firmware/v4l-cx23418-cpu.fw
wget http://linuxtv.org/downloads/firmware/v4l-cx23418-apu.fw
wget http://linuxtv.org/downloads/firmware/v4l-cx23418-dig.fw

echo " * Setting up ad-blocking hosts file"
wget http://ssokolow.com/scripts/upd_hosts.py -O /etc/cron.monthly/upd_hosts.py
chmod +x /etc/cron.monthly/upd_hosts.py
/etc/cron.monthly/upd_hosts.py

echo " * Cursing VirtualBox devs for not allowing snapshot CD image paths to be edited"
ln -s virtualbox /usr/share/virtualbox-ose

if [ ! -e /etc/sensors3.conf ]; then
    echo " * Setting up sensors"
    yes | sensors-detect
else
    echo " * Sensors already set up. Skipping."
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

echo " * Setting login shell to zsh..."
chsh -s /bin/zsh ssokolow

echo " * Creating group 'family' for limited file sharing"
addgroup family

echo " * Adding user 'ssokolow' to requisite groups"
for GRP in tty dialout video lpadmin vboxusers family; do
    gpasswd -a ssokolow "$GRP"
done

if [ -e /srv/inbound ]; then
    echo " * Found /srv/inbound. Setting permissions."
    sudo chown -R ssokolow:family /srv/inbound
    sudo find /srv/inbound -type d -exec chmod 2775 {} \;
    sudo find /srv/inbound -type f -exec chmod a-x {} \;
else
    echo " * No /srv/inbound found. Skipping permissions fix."
fi

echo " * Setting up basic firewall"
cp -n "`dirname $0`/supplemental/ufw_rules/"* /etc/ufw/applications.d/
ufw enable
for X in OpenSSH VNC Deluge Dropbox Samba avahi-daemon dhclient ntpd pidgin synergy; do
    ufw allow "$X"
done

echo "IMPORTANT:"
echo " - Now edit /etc/ssh/sshd_config to allow only non-root, pubkey authentication."
echo " - Don't forget to copy xorg.conf from supplemental if you need TwinView."
echo " - Don't forget to restore your crontab."
