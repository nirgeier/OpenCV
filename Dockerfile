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

RUN apt -y install tightvncserver net-tools
RUN apt install -y xfce4
RUN apt install -y --no-install-recommends xfce4-goodies
RUN apt install -y terminator

WORKDIR /
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
RUN wget https://dl.google.com/linux/linux_signing_key.pub
RUN apt-key add linux_signing_key.pub
RUN apt update
RUN apt install -y google-chrome-stable
RUN apt install -y vlc
RUN apt install -y vim
RUN apt install -y sudo

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

# Isntall all the requirements
RUN apt install -y \
  build-essential  \
  chromium-browser \
  cmake \
  gfortran \
  git \
  libatlas-base-dev \
  libavcodec-dev \
  libavformat-dev \
  libgtk-3-dev \
  libjpeg-dev \
  libpng-dev \
  libpq-dev \
  libswscale-dev \
  libtbb-dev \
  libtbb2 \
  libtiff-dev \
  libv4l-dev \
  libx264-dev \
  libxvidcore-dev \
  net-tools \
  pkg-config  \
  synaptic\
  terminator \
  tightvncserver \
  unzip \
  xfonts-base \
  yasm \
  software-properties-common

# Remove old python versions
RUN apt autoremove -y \
  && apt update \
  && apt upgrade -y \
  && apt install -y python3.7 python3.7-dev python-pip \
  && rm -rf /var/lib/apt/lists/*

# Install pip
RUN pip install numpy virtualenv virtualenvwrapper \
  && rm -rf ~/get-pip.py ~/.cache/pip \
  && dpkg-reconfigure dash 

SHELL ["/bin/bash", "-c"]

# Download OpenCV
WORKDIR /
ENV OPENCV_VERSION="4.1.0"
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip \
  && wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip \
  && unzip opencv.zip \
  && unzip opencv_contrib.zip  \
  && mv opencv-${OPENCV_VERSION} opencv \
  && mv opencv_contrib-${OPENCV_VERSION} opencv_contrib

WORKDIR /opencv
RUN mkdir build
WORKDIR /opencv/build
RUN cmake -DBUILD_TIFF=ON \
  -D BUILD_opencv_java=OFF \
  -D BUILD_EXAMPLES=OFF \
  -D OPENCV_ENABLE_NONFREE=ON \
  -D WITH_CUDA=OFF \
  -D WITH_OPENGL=ON \
  -D WITH_OPENCL=ON \
  -D WITH_IPP=ON \
  -D WITH_TBB=ON \
  -D WITH_EIGEN=ON \
  -D WITH_V4L=ON \
  -D BUILD_TESTS=OFF \
  -D BUILD_PERF_TESTS=OFF \
  -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=$(python3.7 -c "import sys; print(sys.prefix)") \
  -D PYTHON_EXECUTABLE=$(which python3.7) \
  -D PYTHON_INCLUDE_DIR=$(python3.7 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
  -D PYTHON_PACKAGES_PATH=$(python3.7 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
  ..  

RUN make install
RUN make -j4
