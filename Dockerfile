FROM ubuntu:18.04 as ubuntuVNC

# update to local repo
RUN sed -i 's#http://archive.ubuntu.com/#http://il.archive.ubuntu.com/#' /etc/apt/sources.list; 

USER 0

# Expose VNC ports
EXPOSE 6080
EXPOSE 5901

# Set time zone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jerusalem
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update
RUN apt-get upgrade -y 

# Install this in orde to be able to use 'add-apt-repository'
RUN apt-get install -y software-properties-common
RUN add-apt-repository universe

# Add lates git repository
RUN add-apt-repository ppa:git-core/ppa -y

# Isntall all teh requirements
RUN apt-get install -y \
  software-properties-common \ 
  # Install GUI
  xfce4 \
  xfce4-goodies \
  xubuntu-desktop \
  # VNc/NoVNC server
  tightvncserver \ 
  synaptic \
  vim \
  sudo \
  wget \ 
  # Terminal
  terminator \ 
  # Web Browser
  chromium-browser \
  # Video player
  vlc \
  # git lates version
  git

# vncserevr settings
RUN mkdir $HOME/.vnc/ \
  # Set the vnc password will be used for VNc and for noVNC
  && echo "1" | vncpasswd -f > $HOME/.vnc/passwd \
  && touch $HOME/.Xauthority \
  && chmod 600 $HOME/.vnc/passwd $HOME/.Xauthority \
  && echo "#!/bin/bash" > $HOME/.vnc/xstartup \
  # Set the vnc startup script
  #    .Xresources is where a user can make changes to certain settings of the graphical desktop, 
  #    like terminal colors, cursor themes, and font rendering. 
  && echo "xrdb $HOME/.Xresources" >> $HOME/.vnc/xstartup \
  && echo "startxfce4 &" >> $HOME/.vnc/xstartup \
  && chmod +x $HOME/.vnc/xstartup 

# Install noVNC - HTML5 based VNC viewer
RUN mkdir -p $HOME/novnc/utils/websockify \
  && wget -qO- https://github.com/novnc/noVNC/archive/v1.0.0.tar.gz | tar xz --strip 1 -C $HOME/novnc \
  # use older version of websockify to prevent hanging connections on offline containers, see https://github.com/ConSol/docker-headless-vnc-container/issues/50
  && wget -qO- https://github.com/novnc/websockify/archive/v0.6.1.tar.gz | tar xz --strip 1 -C $HOME/novnc/utils/websockify \
  && chmod +x -v $HOME/novnc/utils/*.sh \
  ## create index.html to forward automatically to `vnc_lite.html`
  && ln -s $HOME/novnc/vnc_lite.html $HOME/novnc/index.html

# Start the VNC and the noVNC
RUN echo "#!/bin/sh" > $HOME/startVNC.sh \
  && echo "set -e" >> $HOME/startVNC.sh \
  && echo "sudo vncserver -geometry 1200x1080 -depth 32" >> $HOME/startVNC.sh \
  && echo "sudo $HOME/novnc/utils/launch.sh --vnc localhost:5901 &" >> $HOME/startVNC.sh \
  && chmod 777  $HOME/startVNC.sh 

