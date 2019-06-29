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
  && echo "${vnc_password}" | vncpasswd -f > $HOME/.vnc/passwd \
  && touch $HOME/.Xauthority \
  && chmod 600 $HOME/.vnc/passwd $HOME/.Xauthority 

# Set the vnc startup script
#    .Xresources is where a user can make changes to certain settings of the graphical desktop, 
#    like terminal colors, cursor themes, and font rendering.
RUN echo "#!/bin/bash" > $HOME/.vnc/xstartup
RUN echo "xrdb $HOME/.Xresources" >> $HOME/.vnc/xstartup
RUN echo "startxfce4 &" >> $HOME/.vnc/xstartup
RUN chmod +x $HOME/.vnc/xstartup

RUN echo "Starting server ..... "
RUN export USER=root && vncserver

##################################
### Open cv
##################################
FROM ubuntuVNC

ENV OPENCV_VERSION="4.1.0"

# Switch to root user to install additional software
USER 0

SHELL ["/bin/bash", "-c"]
# RUN echo $SHELL
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get autoremove -y

# developer tools
RUN apt-get install -y \
  build-essential \
  cmake \
  unzip \
  pkg-config 

# image and video I/O libraries
RUN apt-get install -y \
  libjpeg-dev \
  libpng-dev \
  libtiff-dev \
  libavcodec-dev \
  libavformat-dev \
  libswscale-dev \
  libv4l-dev \
  libxvidcore-dev \
  libx264-dev

# install GTK for our GUI backend
RUN apt-get install -y libgtk-3-dev

# mathematical optimizations for OpenCV
RUN apt-get install -y \
  libatlas-base-dev \
  gfortran

# Python 3 development headers
RUN apt-get install -y python3-dev

# Configure your Python 3 virtual environment for OpenCV 4
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3 get-pip.py

RUN pip install virtualenv virtualenvwrapper numpy
RUN rm -rf ~/get-pip.py ~/.cache/pip

SHELL ["/bin/bash", "-c"]

RUN echo -e "\n# virtualenv and virtualenvwrapper" >> ~/.bashrc
RUN echo "export WORKON_HOME=$HOME/.virtualenvs" >> ~/.bashrc
RUN echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> ~/.bashrc
RUN echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
RUN source ~/.bashrc \
  && mkvirtualenv cv --python=/usr/bin/python3 \
  && workon cv \ 
  && wget -O opencv.zip https://github.com/opencv/opencv/archive/4.0.0.zip \
  && wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.0.0.zip \
  && unzip opencv.zip \
  && unzip opencv_contrib.zip \
  && mv opencv-4.1.0 opencv \
  && mv opencv_contrib-4.1.0 opencv_contrib \
  && cd ~/opencv  \
  && mkdir build \
  && cd build \
  && cmake \
  -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/usr/local \
  -D INSTALL_PYTHON_EXAMPLES=OFF \
  -D INSTALL_C_EXAMPLES=OFF \
  -D OPENCV_ENABLE_NONFREE=ON \
  -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
  -D PYTHON_EXECUTABLE=~/.virtualenvs/cv/bin/python \
  -D BUILD_EXAMPLES=OFF .. \
  && make -j1 \
  && make install \
  && ldconfig \ 
  && workon cv \ 
  && ls /usr/local/python/cv2/python-3.5 \
  && cv2.cpython-35m-x86_64-linux-gnu.so \
  && cd /usr/local/python/cv2/python-3.5 \
  && mv cv2.cpython-35m-x86_64-linux-gnu.so cv2.so \
  && cd ~/.virtualenvs/cv/lib/python3.5/site-packages/ \
  && ln -s /usr/local/python/cv2/python-3.5/cv2.so cv2.so \ 
  && workon cv
