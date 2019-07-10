FROM nirgeier/ubuntu_desktop

USER 0

EXPOSE 5901
EXPOSE 6080

# update to local repo
RUN sed -i 's#http://archive.ubuntu.com/#http://il.archive.ubuntu.com/#' /etc/apt/sources.list; 
RUN sed -i 's#http://security.ubuntu.com/#http://il.archive.ubuntu.com/#' /etc/apt/sources.list; 

# Set time zone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jerusalem
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update 
RUN apt upgrade -y 
RUN apt autoremove -y

RUN apt install -y ubuntu-unity-desktop
RUN apt -y install novnc websockify python-numpy

RUN apt -y install tightvncserver net-tools sudo 
RUN apt install -y xfce4 xfce4-goodies 
RUN apt install -y terminator

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

RUN echo "\n\n--- VNC / NoVnc setup" >> ~/.bashrc \
    && echo "export USER=root"  >> ~/.bashrc \
    && echo "sudo vncserver -geometry 1900x1080 -depth 24 &"  >> ~/.bashrc \
    && echo "sudo $HOME/novnc/utils/launch.sh --vnc localhost:5901 &"  >> ~/.bashrc 

# WORKDIR /etc/ssl 
# RUN openssl req -x509 -nodes -newkey rsa:2048 -keyout novnc.pem -out novnc.pem -days 365 
# RUN chmod 777 novnc.pem

