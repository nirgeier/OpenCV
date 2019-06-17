FROM ubuntu

USER 0

# Set time zone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jerusalem
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y xfce4 
RUN apt-get install -y xfce4-goodies
RUN apt-get install -y xubuntu-core^
RUN apt-get install --no-install-recommends ubuntu-desktop 
RUN apt-get install --no-install-recommends gnome-panel 
RUN apt-get install --no-install-recommends gnome-settings-daemon 
RUN apt-get install --no-install-recommends metacity 
RUN apt-get install --no-install-recommends nautilus 
RUN apt-get install --no-install-recommends gnome-terminal -y
RUN apt-get -y install tightvncserver

# ENV DISPLAY=:1 \
#   VNC_PORT=5901 \
#   NO_VNC_PORT=6901
# EXPOSE $VNC_PORT $NO_VNC_PORT

# EXPOSE 5901 6901
# ENV HOME=/ \
#   TERM=xterm \
#   STARTUPDIR=/dockerstartup \
#   INST_SCRIPTS=/headless/install \
#   NO_VNC_HOME=/headless/noVNC \
#   DEBIAN_FRONTEND=noninteractive \
#   VNC_COL_DEPTH=24 \
#   VNC_RESOLUTION=1280x1024 \
#   VNC_PW=vncpassword \
#   VNC_VIEW_ONLY=false

# WORKDIR $HOME

# CMD ["--wait"]
# start the vnc to configure it
# vncserver

