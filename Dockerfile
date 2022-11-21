FROM ubuntu:latest

ARG username=${username:-"user"}
ARG password=${password:-"p@ssw0rd123"}

USER root

# Change root password.
RUN echo "root:${password}" | chpasswd

ADD . /code
WORKDIR /code

# Add necessary permissions to /code
RUN chmod -R 777 /code

# Add non-root user.
RUN useradd -m -s /bin/bash --create-home --base-dir /home $username
RUN echo "$username:${password}" | chpasswd
RUN usermod -aG sudo $username
RUN mkdir -p /etc/sudoers.d && \
    echo "$username ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$username && \
    chmod 0440 /etc/sudoers.d/$username

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update \
  && apt upgrade -y \
  && apt install --no-install-recommends -y  \
     build-essential \
     apt-utils \
     openssh-server \
     tightvncserver \
     autocutsel \
     xfonts-base \
     dbus-x11 \
     sudo \
     make \
     cmake \
     bash \
     python3 \
     git \
     xfce4 \
     xfce4-terminal \
     xfce4-pulseaudio-plugin \
     pavucontrol \
     pulseaudio \
     libasound2-dev \
     faenza-icon-theme \
     snap \
     snapd \
     firefox \
     wget \
     curl \
     nano \
     vim \
  && apt clean autoclean \
  && apt autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}

RUN unset DEBIAN_FRONTEND

# Configure ssh.
RUN mkdir -p /var/run/sshd

# Allow root login via ssh.
RUN sed -i 's/#\?PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Allow ssh password authentication.
RUN sed -i 's/#\?PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login.
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN ( \
    echo 'PermitRootLogin yes'; \
    echo 'PasswordAuthentication yes'; \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
  ) > /etc/ssh/sshd_config_jetbrains

ADD noVNC /opt/noVNC
ADD websockify /opt/noVNC/utils/websockify

ADD utilities/script.js /opt/noVNC/script.js
ADD utilities/audify.js /opt/noVNC/audify.js
ADD utilities/vnc.html /opt/noVNC/vnc.html
ADD utilities/pcm-player.js /opt/noVNC/pcm-player.js

# Install n for Node version management.
RUN curl -L https://git.io/n-install | bash -s -- -y

# Install Node.js LTS.
RUN /root/n/bin/n lts

# Install npm and pnpn.
RUN npm install -g npm pnpm

RUN pnpm install --prefix /opt/noVNC ws audify

# Add entrypoint script.
ADD entrypoint.sh /entrypoint.sh

# Add permissions to entrypoint script.
RUN chmod 777 /entrypoint.sh

# Use docker-bash-rc file to set up bash and make it pretty.
ADD utilities/docker-etc-profile.sh /etc/docker-etc-profile.sh
RUN chmod 777 /etc/docker-etc-profile.sh
RUN echo "source /etc/docker-etc-profile.sh" >> /root/.bashrc

# Install CLion.
RUN utilities/install_clion.sh

USER $username
WORKDIR /home/$username

RUN echo "source /etc/docker-etc-profile.sh" >> /home/$username/.bashrc

# Configure vnc.
RUN mkdir -p /home/$username/.vnc \
    && echo "-SecurityTypes=none" > /home/$username/.vnc/config

RUN echo "#!/bin/sh\n\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\n\nxrdb \"$HOME/.Xresources\"\nautocutsel -fork\nstartxfce4 &" > /home/$username/.vnc/xstartup

# Add permissions to vnc.
RUN chmod +x /home/$username/.vnc/xstartup

RUN touch /home/$username/.Xauthority
RUN touch /home/$username/.Xresources

# Configure vnc password.
RUN printf "${password}\n${password}\n\n" | vncpasswd

# Expose ssh, vnc and noVNC ports.
EXPOSE 22 5999 6080

# Start ssh, vnc and noVNC.
CMD [ "/bin/bash", "/entrypoint.sh" ]
