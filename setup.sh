apt-get update 
apt-get upgrade -y
apt-get install -y build-essential cmake unzip pkg-config libjpeg-dev libpng-dev libtiff-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libgtk-3-dev libatlas-base-dev gfortran python3-dev
cd ~
wget -O opencv.zip https://github.com/opencv/opencv/archive/4.0.0.zip
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.0.0.zip
wget -O people-counting-opencv.zip http://t.dripemail2.com/c/eyJhY2NvdW50X2lkIjoiNDc2ODQyOSIsImRlbGl2ZXJ5X2lkIjoiNjg2MzY0MDM0OSIsInVybCI6Imh0dHA6Ly9weWltZy5jby96c2Y4Yj9fX3M9b2RmenRkdWttcWd1cHF6enFjdGIifQ
unzip opencv.zip
unzip opencv_contrib.zip
mv opencv-4.0.0 opencv
mv opencv_contrib-4.0.0 opencv_contrib
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
pip install virtualenv virtualenvwrapper
rm -rf ~/get-pip.py ~/.cache/pip
dpkg-reconfigure dash
echo "\n# virtualenv and virtualenvwrapper" >> ~/.bashrc
echo "export WORKON_HOME=$HOME/.virtualenvs" >> ~/.bashrc
echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> ~/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
SHELL ["/bin/bash", "-c"]
cat ~/.bashrc 
source ~/.bashrc

SHELL ["/bin/bash", "-c"]
workon cv

pip install numpy
cd ~/opencv
mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/usr/local \
  -D INSTALL_PYTHON_EXAMPLES=ON \
  -D INSTALL_C_EXAMPLES=OFF \
  -D OPENCV_ENABLE_NONFREE=ON \
  -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
  -D PYTHON_EXECUTABLE=~/.virtualenvs/cv/bin/python \
  -D BUILD_EXAMPLES=ON ..
make -j4	
make install
ldconfig
workon cv
python --version

