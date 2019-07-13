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

# Isntall all the requirements
RUN apt install -y software-properties-common
RUN apt install -y xfce4
RUN apt install -y wget
RUN apt install -y --no-install-recommends xfce4-goodies
RUN apt install -y novnc 
RUN apt install -y websockify 
RUN apt install -y python-numpy
RUN apt install -y tightvncserver 
RUN apt install -y net-tools
RUN apt install -y terminator
RUN apt install -y build-essential  
RUN apt install -y cmake 
RUN apt install -y gfortran 
RUN apt install -y git 
RUN apt install -y libatlas-base-dev 
RUN apt install -y libavcodec-dev 
RUN apt install -y libavformat-dev 
RUN apt install -y libgtk-3-dev 
RUN apt install -y libjpeg-dev 
RUN apt install -y libpng-dev 
RUN apt install -y libpq-dev 
RUN apt install -y libswscale-dev 
RUN apt install -y libtbb-dev 
RUN apt install -y libtbb2 
RUN apt install -y libtiff-dev 
RUN apt install -y libv4l-dev 
RUN apt install -y libx264-dev 
RUN apt install -y libxvidcore-dev 
RUN apt install -y net-tools 
RUN apt install -y pkg-config  
RUN apt install -y synaptic
RUN apt install -y terminator 
RUN apt install -y tightvncserver 
RUN apt install -y unzip 
RUN apt install -y xfonts-base 
RUN apt install -y yasm 
RUN apt install -y vlc
RUN apt install -y vim
RUN apt install -y sudo
RUN apt install -y python3.7 
RUN apt install -y python3.7-dev 
RUN apt install -y python-pip

WORKDIR /
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
RUN wget https://dl.google.com/linux/linux_signing_key.pub
RUN apt-key add linux_signing_key.pub
RUN apt update
RUN apt install -y google-chrome-stable

# Install pip
RUN pip install numpy virtualenv virtualenvwrapper \
  && rm -rf ~/get-pip.py ~/.cache/pip \
  && dpkg-reconfigure dash 

RUN apt autoremove -y \
  && apt update \
  && apt upgrade -y \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update
RUN apt install -y curl

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

# # Download visual studio code
WORKDIR /root/Desktop

# Download visual studio code
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
  && install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ \
  && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list' \
  && apt install -y apt-transport-https \
  && apt update \
  && apt install -y code \
  && rm microsoft.gpg \
  # Fix known bug with VSCode & Electron
  #     Ticket: https://github.com/Microsoft/vscode/issues/3451
  && mkdir ~/lib \
  && cp /usr/lib/x86_64-linux-gnu/libxcb.so.1 ~/lib \
  && sed -i 's/BIG-REQUESTS/_IG-REQUESTS/' ~/lib/libxcb.so.1 \
  # set the dynamic loader path to put your library first before executing VS Code
  && export LD_LIBRARY_PATH=$HOME/lib

##########################
###  DESKTOP SHORTCUTS ###
##########################
# Chrome shortcut
RUN mkdir -p ~/Desktop \
  && echo "#!/usr/bin/env xdg-open" >> ~/Desktop/chrome.desktop \
  && echo "[Desktop Entry]" >> ~/Desktop/chrome.desktop \
  && echo "Version=1.0" >> ~/Desktop/chrome.desktop \
  && echo "Type=Application" >> ~/Desktop/chrome.desktop \
  && echo "Terminal=false" >> ~/Desktop/chrome.desktop \
  && echo "Exec=/usr/bin/google-chrome --no-sandbox" >> ~/Desktop/chrome.desktop \
  && echo "Name=Chrome" >> ~/Desktop/chrome.desktop \
  && echo "Comment=Chrome" >> ~/Desktop/chrome.desktop \
  && echo "Icon=/usr/share/icons/hicolor/48x48/apps/google-chrome.png" >> ~/Desktop/chrome.desktop \
  && chmod +x ~/Desktop/chrome.desktop 

# VLC shortcut
RUN mkdir -p ~/Desktop \
  && echo "#!/usr/bin/env xdg-open" >> ~/Desktop/vlc.desktop \
  && echo "[Desktop Entry]" >> ~/Desktop/vlc.desktop \
  && echo "Version=1.0" >> ~/Desktop/vlc.desktop \
  && echo "Type=Application" >> ~/Desktop/vlc.desktop \
  && echo "Terminal=false" >> ~/Desktop/vlc.desktop \
  && echo "Exec=/usr/bin/vlc --no-qt-privacy-ask" >> ~/Desktop/vlc.desktop \
  && echo "Name=vlc" >> ~/Desktop/vlc.desktop \
  && echo "Comment=VLC" >> ~/Desktop/vlc.desktop \
  && echo "Icon=/usr/share/icons/hicolor/48x48/apps/vlc.png" >> ~/Desktop/vlc.desktop \
  && chmod +x ~/Desktop/vlc.desktop 

# VSCode shortcut
RUN mkdir -p ~/Desktop \
  mkdir -p ~/Desktop/Projects/.vscode \
  && echo "#!/usr/bin/env xdg-open" >> ~/Desktop/VSCode.desktop \
  && echo "[Desktop Entry]" >> ~/Desktop/VSCode.desktop \
  && echo "Version=1.0" >> ~/Desktop/VSCode.desktop \
  && echo "Type=Application" >> ~/Desktop/VSCode.desktop \
  && echo "Terminal=false" >> ~/Desktop/VSCode.desktop \
  && echo "Exec=env LD_LIBRARY_PATH=$HOME/lib /usr/bin/code --user-data-dir ./Projects/.vscode" >> ~/Desktop/VSCode.desktop \
  && echo "Name=VSCode" >> ~/Desktop/VSCode.desktop \
  && echo "Comment=VSCode" >> ~/Desktop/VSCode.desktop \
  && echo "Icon=/usr/share/pixmaps/com.visualstudio.code.png" >> ~/Desktop/VSCode.desktop \
  && chmod +x ~/Desktop/VSCode.desktop 

# Download People counter script
RUN wget -O people-counting-opencv.zip http://t.dripemail2.com/c/eyJhY2NvdW50X2lkIjoiNDc2ODQyOSIsImRlbGl2ZXJ5X2lkIjoiNjg2MzY0MDM0OSIsInVybCI6Imh0dHA6Ly9weWltZy5jby96c2Y4Yj9fX3M9b2RmenRkdWttcWd1cHF6enFjdGIifQ \
  && unzip people-counting-opencv.zip -d ~/Desktop/Projects

SHELL ["/bin/bash", "-c"]

# # Download OpenCV
# WORKDIR /
# ENV OPENCV_VERSION="4.1.0"
# RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip \
#   && wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip \
#   && unzip opencv.zip \
#   && unzip opencv_contrib.zip  \
#   && mv opencv-${OPENCV_VERSION} opencv \
#   && mv opencv_contrib-${OPENCV_VERSION} opencv_contrib

# WORKDIR /opencv
# RUN mkdir build
# WORKDIR /opencv/build
# RUN cmake -DBUILD_TIFF=ON \
#   -D BUILD_opencv_java=OFF \
#   -D BUILD_EXAMPLES=OFF \
#   -D OPENCV_ENABLE_NONFREE=ON \
#   -D WITH_CUDA=OFF \
#   -D WITH_OPENGL=ON \
#   -D WITH_OPENCL=ON \
#   -D WITH_IPP=ON \
#   -D WITH_TBB=ON \
#   -D WITH_EIGEN=ON \
#   -D WITH_V4L=ON \
#   -D BUILD_TESTS=OFF \
#   -D BUILD_PERF_TESTS=OFF \
#   -D CMAKE_BUILD_TYPE=RELEASE \
#   -D CMAKE_INSTALL_PREFIX=$(python3.7 -c "import sys; print(sys.prefix)") \
#   -D PYTHON_EXECUTABLE=$(which python3.7) \
#   -D PYTHON_INCLUDE_DIR=$(python3.7 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
#   -D PYTHON_PACKAGES_PATH=$(python3.7 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
#   ..  

# RUN make install
# RUN make -j4

# RUN apt update
# RUN apt install -y curl
# RUN apt autoremove

