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

RUN apt update
RUN apt upgrade -y 

# Install this in orde to be able to use 'add-apt-repository'
RUN apt install --no-install-recommends -y software-properties-common

# Add repositories
RUN add-apt-repository universe 
RUN add-apt-repository ppa:git-core/ppa -y
RUN add-apt-repository -y ppa:deadsnakes/ppa

# Install GUI
RUN apt install -y xfce4 xfce4-goodies 

# Isntall all the requirements
RUN apt install --no-install-recommends -y \
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
  sudo \
  synaptic\
  terminator \
  tightvncserver \
  unzip \
  vim \
  vlc \
  wget  \
  xfonts-base \
  yasm \
  software-properties-common 

# Clean & remove unused packages
RUN apt update
RUN apt upgrade -y 
RUN apt autoremove -y 

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

# Remove old python versions
RUN apt purge -y python2.7 python3.6 && apt autoremove -y 
RUN apt autoremove -y

RUN apt update \
  && apt upgrade -y \
  && apt install -y python3.7 python3.7-dev python-pip \
  && rm -rf /var/lib/apt/lists/*

# Download OpenCV
WORKDIR /
ENV OPENCV_VERSION="4.1.0"
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip
RUN unzip opencv.zip 
RUN unzip opencv_contrib.zip 
RUN mv opencv-${OPENCV_VERSION} opencv
RUN mv opencv_contrib-${OPENCV_VERSION} opencv_contrib

# Install pip
RUN wget https://bootstrap.pypa.io/get-pip.py \
  && python3 get-pip.py \
  && pip install numpy virtualenv virtualenvwrapper \
  && rm -rf ~/get-pip.py ~/.cache/pip \
  && dpkg-reconfigure dash 

SHELL ["/bin/bash", "-c"]

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

# Start the VNC and the noVNC

RUN echo "# virtualenv and virtualenvwrapper" >> ~/.bashrc \
  && echo "export WORKON_HOME=$HOME/.virtualenvs" >> ~/.bashrc \
  && echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python" >> ~/.bashrc \
  && echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc \
  && echo "mkvirtualenv cv -p python3" >> ~/.bashrc \
  echo "\n\n--- VNC / NoVnc setup" >> ~/.bashrc \
  && echo "export USER=root"  >> ~/.bashrc \
  && echo "sudo vncserver -geometry 1900x1080 -depth 24 &"  >> ~/.bashrc \
  && echo "sudo $HOME/novnc/utils/launch.sh --vnc localhost:5901 &"  >> ~/.bashrc 
