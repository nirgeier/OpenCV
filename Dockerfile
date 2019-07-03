# FROM ubuntu:18.04 as ubuntuVNC

# # update to local repo
# RUN sed -i 's#http://archive.ubuntu.com/#http://il.archive.ubuntu.com/#' /etc/apt/sources.list; 

# USER 0

# # Expose VNC ports
# EXPOSE 6080
# EXPOSE 5901

# # Set time zone
# ENV DEBIAN_FRONTEND=noninteractive
# ENV TZ=Asia/Jerusalem
# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# RUN apt update
# RUN apt upgrade -y 

# # Install this in orde to be able to use 'add-apt-repository'
# RUN apt install -y software-properties-common
# RUN add-apt-repository universe

# # Add lates git repository
# RUN add-apt-repository ppa:git-core/ppa -y

# # Isntall all the requirements
# RUN apt install -y \
#   software-properties-common \ 
#   # Install GUI
#   xfce4 \
#   xfce4-goodies \
#   xubuntu-desktop \
#   # VNc/NoVNC server
#   tightvncserver \ 
#   synaptic \
#   vim \
#   sudo \
#   wget \ 
#   # Terminal
#   terminator \ 
#   # Web Browser
#   chromium-browser \
#   # Video player
#   vlc \
#   # git lates version
#   git

# RUN apt install  -y xfonts-base

# # vncserevr settings
# RUN mkdir $HOME/.vnc/ \
#   # Set the vnc password will be used for VNc and for noVNC
#   && echo "1" | vncpasswd -f > $HOME/.vnc/passwd \
#   && touch $HOME/.Xauthority \
#   && chmod 600 $HOME/.vnc/passwd $HOME/.Xauthority \
#   && echo "#!/bin/bash" > $HOME/.vnc/xstartup \
#   # Set the vnc startup script
#   #    .Xresources is where a user can make changes to certain settings of the graphical desktop, 
#   #    like terminal colors, cursor themes, and font rendering. 
#   && echo "xrdb $HOME/.Xresources" >> $HOME/.vnc/xstartup \
#   && echo "startxfce4 &" >> $HOME/.vnc/xstartup \
#   && chmod +x $HOME/.vnc/xstartup 

# # Install noVNC - HTML5 based VNC viewer
# RUN mkdir -p $HOME/novnc/utils/websockify \
#   && wget -qO- https://github.com/novnc/noVNC/archive/v1.0.0.tar.gz | tar xz --strip 1 -C $HOME/novnc \
#   # use older version of websockify to prevent hanging connections on offline containers, see https://github.com/ConSol/docker-headless-vnc-container/issues/50
#   && wget -qO- https://github.com/novnc/websockify/archive/v0.6.1.tar.gz | tar xz --strip 1 -C $HOME/novnc/utils/websockify \
#   && chmod +x -v $HOME/novnc/utils/*.sh \
#   ## create index.html to forward automatically to `vnc_lite.html`
#   && ln -s $HOME/novnc/vnc_lite.html $HOME/novnc/index.html

# # Start the VNC and the noVNC
# RUN echo "#!/bin/sh" > $HOME/startVNC.sh \
#   && echo "set -e" >> $HOME/startVNC.sh \
#   && echo "sudo vncserver -geometry 1200x1080 -depth 24" >> $HOME/startVNC.sh \
#   && echo "sudo $HOME/novnc/utils/launch.sh --vnc localhost:5901 &" >> $HOME/startVNC.sh \
#   && chmod 777 $HOME/startVNC.sh 


FROM ubuntu

RUN apt update \
  && apt upgrade -y \
  && apt install -y \
  software-properties-common \
  build-essential  \
  cmake \
  unzip \
  pkg-config  \
  libjpeg-dev \
  libpng-dev \
  libtiff-dev \
  libavcodec-dev \
  libavformat-dev \
  libswscale-dev \
  libv4l-dev \
  libxvidcore-dev \
  libx264-dev \
  libgtk-3-dev \
  libatlas-base-dev \
  gfortran \
  yasm \
  libtbb2 \
  libtbb-dev \
  libpq-dev \
  python3-dev \
  python-pip \
  && rm -rf /var/lib/apt/lists/*

# Install python3
RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt update
RUN apt install -y python3.7 

RUN pip install numpy

# Download OpenCV
WORKDIR /
ENV OPENCV_VERSION="4.1.0"
#RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip
#RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip
COPY opencv.zip .
COPY opencv_contrib.zip .
RUN unzip opencv.zip 
RUN unzip opencv_contrib.zip 
RUN mv opencv-${OPENCV_VERSION} opencv
RUN mv opencv_contrib-${OPENCV_VERSION} opencv_contrib

# Install pip
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3 get-pip.py
RUN pip install virtualenv virtualenvwrapper
RUN rm -rf ~/get-pip.py ~/.cache/pip
RUN dpkg-reconfigure dash

RUN echo "# virtualenv and virtualenvwrapper" >> ~/.bashrc \
  && echo "export WORKON_HOME=$HOME/.virtualenvs" >> ~/.bashrc \
  && echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.7" >> ~/.bashrc \
  && echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc \
  && echo "mkvirtualenv cv -p python3" >> ~/.bashrc 

SHELL ["/bin/bash", "-c"]

# RUN apt remove -y --purge python* 
# RUN apt autoremove -y
# RUN apt update
# RUN apt remove --purge -y thunderbird
# RUN apt upgrade -y 

# RUN apt install -y python3.7

# WORKDIR /opencv
# RUN mkdir build
# WORKDIR /opencv/build
# RUN cmake -DBUILD_TIFF=ON \
#   -DBUILD_opencv_java=OFF \
#   -DWITH_CUDA=OFF \
#   -DWITH_OPENGL=ON \
#   -DWITH_OPENCL=ON \
#   -DWITH_IPP=ON \
#   -DWITH_TBB=ON \
#   -DWITH_EIGEN=ON \
#   -DWITH_V4L=ON \
#   -DBUILD_TESTS=OFF \
#   -DBUILD_PERF_TESTS=OFF \
#   -DCMAKE_BUILD_TYPE=RELEASE \
#   -DCMAKE_INSTALL_PREFIX=$(python3.7 -c "import sys; print(sys.prefix)") \
#   -DPYTHON_EXECUTABLE=$(which python3.7) \
#   -DPYTHON_INCLUDE_DIR=$(python3.7 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
#   -DPYTHON_PACKAGES_PATH=$(python3.7 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
#   .. 

# RUN make install
# RUN ln -s \
#   /usr/local/python/cv2/python-3.7/cv2.cpython-37m-x86_64-linux-gnu.so \
#   /usr/local/lib/python3.7/site-packages/cv2.so

