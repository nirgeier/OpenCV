FROM ubuntu:18.04 as ubuntuVNC

# update to local repo
RUN sed -i 's#http://archive.ubuntu.com/#http://il.archive.ubuntu.com/#' /etc/apt/sources.list; 

USER 0

ARG vnc_password=""
EXPOSE 5901

# built-in packages
RUN apt update 
RUN apt upgrade -y 

RUN apt-get install -y software-properties-common

# Set time zone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jerusalem
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN add-apt-repository universe
RUN apt-get update
RUN apt-get upgrade -y 
RUN apt-get install -y \
  xfce4 \
  xfce4-goodies \
  xubuntu-desktop \
  tightvncserver \
  synaptic \
  vim \
  sudo \
  wget \ 
  terminator \
  chromium-browser \
  vlc

# Install latest git version
RUN add-apt-repository ppa:git-core/ppa -y \
  && apt update \ 
  && apt install -y git

# Set the empty password for the vncserevr
RUN mkdir $HOME/.vnc/ \
  && echo "1" | vncpasswd -f > $HOME/.vnc/passwd \
  && touch $HOME/.Xauthority \
  && chmod 600 $HOME/.vnc/passwd $HOME/.Xauthority \
  # Set the vnc startup script
  #    .Xresources is where a user can make changes to certain settings of the graphical desktop, 
  #    like terminal colors, cursor themes, and font rendering. 
  && echo "#!/bin/bash" > $HOME/.vnc/xstartup \
  && echo "xrdb $HOME/.Xresources" >> $HOME/.vnc/xstartup \
  && echo "startxfce4 &" >> $HOME/.vnc/xstartup \
  && chmod +x $HOME/.vnc/xstartup 

RUN echo "Install noVNC - HTML5 based VNC viewer"
EXPOSE 6080
EXPOSE 5901
RUN mkdir -p $HOME/novnc/utils/websockify \
  && wget -qO- https://github.com/novnc/noVNC/archive/v1.0.0.tar.gz | tar xz --strip 1 -C $HOME/novnc \
  # use older version of websockify to prevent hanging connections on offline containers, see https://github.com/ConSol/docker-headless-vnc-container/issues/50
  && wget -qO- https://github.com/novnc/websockify/archive/v0.6.1.tar.gz | tar xz --strip 1 -C $HOME/novnc/utils/websockify \
  && chmod +x -v $HOME/novnc/utils/*.sh \
  ## create index.html to forward automatically to `vnc_lite.html`
  && ln -s $HOME/novnc/vnc_lite.html $HOME/novnc/index.html

CMD "sudo vncserver && $HOME/novnc/utils/launch.sh --vnc localhost:5901"
