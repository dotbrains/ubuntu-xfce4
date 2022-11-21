#!/bin/bash

# set USER env variable
export USER=$(whoami)

# Generate ssh host keys
sudo ssh-keygen -A

# Run sshd
/usr/sbin/sshd -D -e -f /etc/ssh/sshd_config_jetbrains &

# Start the VNCServer
/usr/bin/vncserver :99 -geometry 1920x1080 -depth 24 &

# Start pulseaudio
/usr/bin/pulseaudio &

# Start audify (audio redirection) for pulseaudio and noVNC
/usr/bin/node /opt/noVNC/audify.js &

# Start the noVNC server using the proxy
/opt/noVNC/utils/novnc_proxy --vnc localhost:5999