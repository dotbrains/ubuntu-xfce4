#!/bin/bash

# Run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Install necessary packages
apt update \
  && apt upgrade -y \
  && apt install --no-install-recommends -y \
    wget \
    tar \
  && apt clean autoclean \
  && apt autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}

# Install Firefox
if [ ! -d "/opt/firefox" ]; then
    wget -qO- https://download-installer.cdn.mozilla.net/pub/firefox/releases/79.0/linux-x86_64/en-US/firefox-79.0.tar.bz2 | tar -xj -C /opt
    mv /opt/firefox-* /opt/firefox
fi

# Create an alias for firefox
echo "alias firefox='sh /opt/firefox/firefox &'" >> ~/.bashrc

# Create a desktop entry
cat <<EOF > /usr/share/applications/firefox.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Exec=sh /opt/firefox/firefox
Comment=FireFox answers to no one but you.
Categories=Browser;
Terminal=false
StartupWMClass=firefox
EOF

# Make the desktop entry executable
chmod +x /usr/share/applications/firefox.desktop

# Make the desktop entry visible in the application menu
update-desktop-database