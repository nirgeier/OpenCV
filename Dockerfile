FROM ubuntu

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

#RUN apt install -y ubuntu-unity-desktop
RUN apt -y install novnc websockify python-numpy

RUN apt -y install tightvncserver net-tools sudo 
RUN apt install -y xfce4
RUN apt install -y --no-install-recommends xfce4-goodies
RUN apt install -y terminator sudo

WORKDIR /
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
RUN wget https://dl.google.com/linux/linux_signing_key.pub
RUN apt-key add linux_signing_key.pub
RUN apt update
RUN apt install -y google-chrome-stable
RUN apt install -y vlc
RUN apt install -y vim

##################################
# Hack VLC so it can run as root #
##################################
RUN sudo sed -i 's/geteuid/getppid/' /usr/bin/vlc

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
    && echo "autocutsel -fork" >> $HOME/.vnc/xstartup \
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

RUN echo "#!/bin/bash" >> ~/.firstRun \
    && echo "if [ -z \$VNC_FIRST_RUN ] ;" >> ~/.firstRun \
    && echo "  then " >> ~/.firstRun \
    && echo "    export USER=root" >> ~/.firstRun \
    && echo "    export VNC_FIRST_RUN=1 " >> ~/.firstRun \
    && echo "    vncserver -geometry 1900x1080 -depth 24 &  " >> ~/.firstRun \
    && echo "    $HOME/novnc/utils/launch.sh --vnc localhost:5901 & " >> ~/.firstRun \
    && echo "    vlc --no-qt-privacy-ask --reset-config & " >> ~/.firstRun \
    && echo "fi" >> ~/.firstRun \ 
    && echo "source ~/.firstRun" >> ~/.bashrc \
    && echo "sed -i 's/#vout=/vout=xcb_x11/' ~/.config/vlc/vlcrc " >> ~/.bashrc \
    && chmod +x ~/.firstRun 

#!/usr/bin/env xdg-open
RUN mkdir ~/Desktop \
    && echo "#!/usr/bin/env xdg-open" >> ~/Desktop/chrome.desktop \
    && echo "[Desktop Entry]" >> ~/Desktop/chrome.desktop \
    && echo "Version=1.0" >> ~/Desktop/chrome.desktop \
    && echo "Type=Application" >> ~/Desktop/chrome.desktop \
    && echo "Terminal=false" >> ~/Desktop/chrome.desktop \
    && echo "Exec=/usr/bin/google-chrome --no-sandbox" >> ~/Desktop/chrome.desktop \
    && echo "Name=Chrome" >> ~/Desktop/chrome.desktop \
    && echo "Comment=Chrome" >> ~/Desktop/chrome.desktop \
    && echo "Icon=/usr/share/icons/hicolor/48x48/apps/google-chrome.png " >> ~/Desktop/chrome.desktop \
    && chmod +x ~/Desktop/chrome.desktop 



