FROM dorowu/ubuntu-desktop-lxde-vnc

# update to local repo
RUN sed -i 's#http://tw.archive.ubuntu.com/#http://il.archive.ubuntu.com/#' /etc/apt/sources.list; 

# Set time zone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jerusalem
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update \
  && apt upgrade -y \
  && apt autoremove -y

RUN apt install -y terminator
WORKDIR /
COPY ./install.sh .
RUN chmod +x ./install.sh

# Install this in order to be able to use 'add-apt-repository'
RUN apt install --no-install-recommends -y  software-properties-common
# Add repositories
RUN add-apt-repository universe \
  && add-apt-repository -y ppa:git-core/ppa \
  && add-apt-repository -y ppa:deadsnakes/ppa

RUN apt update \
  && apt autoremove -y 

#   # Isntall all the requirements
RUN apt install -y --no-install-recommends build-essential
RUN apt install -y --no-install-recommends cmake 
RUN apt install -y --no-install-recommends gfortran 
RUN apt install -y --no-install-recommends git 
RUN apt install -y --no-install-recommends libatlas-base-dev 
RUN apt install -y --no-install-recommends libavcodec-dev 
RUN apt install -y --no-install-recommends libavformat-dev 
RUN apt install -y --no-install-recommends libgtk-3-dev 
RUN apt install -y --no-install-recommends libjpeg-dev 
RUN apt install -y --no-install-recommends libpng-dev 
RUN apt install -y --no-install-recommends libpq-dev 
RUN apt install -y --no-install-recommends libswscale-dev 
RUN apt install -y --no-install-recommends libtbb-dev 
RUN apt install -y --no-install-recommends libtbb2 
RUN apt install -y --no-install-recommends libtiff-dev 
RUN apt install -y --no-install-recommends libv4l-dev 
RUN apt install -y --no-install-recommends libx264-dev 
RUN apt install -y --no-install-recommends libxvidcore-dev 
RUN apt install -y --no-install-recommends pkg-config  
RUN apt install -y --no-install-recommends sudo 
RUN apt install -y --no-install-recommends synaptic
RUN apt install -y --no-install-recommends terminator 
RUN apt install -y --no-install-recommends unzip 
RUN apt install -y --no-install-recommends vim 
RUN apt install -y --no-install-recommends vlc 
RUN apt install -y --no-install-recommends xfonts-base 
RUN apt install -y --no-install-recommends yasm
RUN apt install -y --no-install-recommends wget

# Install python3.7
RUN apt autoremove -y \
  && apt update \
  && apt upgrade -y \
  && apt install -y python3.7 python3.7-dev python-pip \
  && rm -rf /var/lib/apt/lists/*

# Download OpenCV
WORKDIR /
ENV OPENCV_VERSION="4.1.0"
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip \
  && wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip \
  && unzip opencv.zip \
  && unzip opencv_contrib.zip \
  && rm opencv.zip \
  && rm opencv_contrib.zip \
  && mv opencv-${OPENCV_VERSION} opencv \
  && mv opencv_contrib-${OPENCV_VERSION} opencv_contrib

# WORKDIR /opencv
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

##################################
# Hack VLC so it can run as root #
##################################
RUN sudo sed -i 's/geteuid/getppid/' /usr/bin/vlc
# Fix the vlc video output format to the supported output
RUN vlc 

RUN sudo ldconfig

# Install required pip packages
RUN pip install numpy virtualenv virtualenvwrapper \
  && rm -rf ~/.cache/pip \
  && dpkg-reconfigure dash 

RUN  echo "# virtualenv and virtualenvwrapper" >> /root/.bashrc \
  && echo "export WORKON_HOME=root/.virtualenvs" >> /root/.bashrc \
  && echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python" >> /root/.bashrc \
  && echo "source /usr/local/bin/virtualenvwrapper.sh" >> /root/.bashrc \
  && echo "mkvirtualenv cv -p python3" >> /root/.bashrc \
  && echo "workon cv" \
  && echo "pip install numpy" 

WORKDIR /root/Desktop
COPY people-counting-opencv.zip /root/Desktop 
RUN unzip /root/Desktop/people-counting-opencv.zip \
  && rm people-counting-opencv.zip

# Download visual studio code
WORKDIR /root/Desktop
# RUN wget -O VSCode.deb https://go.microsoft.com/fwlink/?LinkID=760868 
# RUN apt install ./VSCode.deb

# Download visual studio code
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
  && install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ \
  && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list' \
  && apt install -y apt-transport-https \
  && apt update \
  && apt install -y code \
  && rm microsoft.gpg 


