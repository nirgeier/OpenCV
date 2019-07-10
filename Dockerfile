FROM ubuntu

USER 0

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

