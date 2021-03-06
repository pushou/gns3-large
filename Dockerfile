# Version: 0.7.1
FROM debian:jessie
MAINTAINER pushou 
#
# increase the version to force recompilation of everything
#
ENV GNS3LARGEVERSION 0.0.3
#
# ------------------------------------------------------------------
# environment variables to avoid that dpkg-reconfigure 
# tries to ask the user any questions
#
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV LC_ALL=fr_FR.UTF-8
ENV LANG=fr_FR.UTF-8
RUN echo "deb http://debian.iutbeziers.fr/debian jessie main" > /etc/apt/sources.list

#
# ----------------------------------------------------------------- 
# install needed packages to build and run gns3 and related sw
#


RUN apt-get update && apt-get upgrade -y  && apt-get install -y \
#RUN apt-get install -y \
 git  \
 wget \
 bzip2 \
 build-essential \
 libpcap-dev \
 uuid-dev \
 libelf-dev \
 cmake \
 python3-setuptools \
 python3-pyqt5 \
 python3-pyqt5.qtsvg \
 python3-ws4py \
 python3-netifaces \
 python3-zmq \
 python3-tornado \
 python3-dev \
 bison \
 flex \
 lib32z1 \
 lib32ncurses5 \
 lxterminal \
 telnet \
 python \
 wireshark \ 
 debconf \
 locales \
 flex \
 bison \ 
 apt-utils \
 debconf-utils \
 iproute2 \
 libpcap-dev \
 net-tools \
 sudo \
 cpulimit

ENV LC_ALL=fr_FR.UTF-8
ENV LANG=fr_FR.UTF-8
ENV LANGUAGE=fr_FR:fr
ENV LC_TIME=fr_FR.UTF-8
ENV LC_COLLATE=fr_FR.UTF-8


RUN echo "Europe/Paris" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e 's/# fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="fr_FR.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=fr_FR.UTF-8


#
# -----------------------------------------------------------------
# compile and install dynamips, gns3-server, gns3-gui
#
RUN mkdir /src
RUN cd /src; git clone https://github.com/GNS3/dynamips.git
RUN cd /src/dynamips ; git checkout v0.2.15
RUN mkdir /src/dynamips/build
RUN cd /src/dynamips/build ;  cmake .. ; make ; make install
#
RUN cd /src; git clone https://github.com/GNS3/gns3-gui.git
RUN cd /src; git clone https://github.com/GNS3/gns3-server.git
RUN cd /src/gns3-server ; git checkout v1.4.0 ; python3 setup.py install
RUN cd /src/gns3-gui ; git checkout v1.4.0 ; python3 setup.py install
#
#-----------------------------------------------------------------------
# compile and install vpcs, 64 bit version
#
RUN cd /src ; \
    wget -O - http://sourceforge.net/projects/vpcs/files/0.8/vpcs-0.8-src.tbz/download \
    | bzcat | tar -xvf -
RUN cd /src/vpcs-*/src ; ./mk.sh 64
RUN cp /src/vpcs-*/src/vpcs /usr/local/bin/vpcs
#
# --------------------------------------------------------------------
# compile and install iniparser (needed for iouyap) and 
# iouyap (needed to run iou without additional virtual machine)
#
RUN git clone http://github.com/ndevilla/iniparser.git
RUN cd iniparser ; make; \
cp libiniparser.* /usr/lib ; \
cp src/iniparser.h /usr/local/include/ ; \
cp src/dictionary.h /usr/local/include/
#
RUN cd /src ; git clone https://github.com/GNS3/iouyap.git
#COPY iniparser.h /src/iouyap/iniparser/iniparser.h
RUN cd /src/iouyap ; make
RUN ls /src/iouyap
RUN cd /src/iouyap ; cp iouyap /usr/local/bin
#
# to run iou 32 bit support is needed so add i386 repository, cannot be done
# before compiling dynamips
#
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get -y install \ 
   libssl-dev:i386 \
   libssl1.0.0:i386 \
   qemu \
   uml-utilities \
   iptables
#
# ---------------------------------------------------------------------------
# these links are needed to run IOU
#
RUN ln -s /usr/lib/i386-linux-gnu/libcrypto.so /usr/lib/i386-linux-gnu/libcrypto.so.4
#
#
# prepare startup files /src/misc
#
RUN mkdir /src/misc
#
# install gnome connection manager
#
RUN cd /src/misc; wget http://kuthulu.com/gcm/gnome-connection-manager_1.1.0_all.deb
#RUN cd /src/misc; wget http://va.ler.io/myfiles/deb/gnome-connection-manager_1.1.0_all.deb
RUN apt-get -y install expect python-vte python-glade2
RUN mkdir -p /usr/share/desktop-directories
#RUN cd /src/misc; dpkg -i gnome-connection-manager_1.1.0_all.deb
RUN (while true;do echo;done) | perl -MCPAN -e 'install JSON::Tiny'
RUN (while true;do echo;done) | perl -MCPAN -e 'install File::Slurp'
#RUN cd /usr/local/bin; ln -s /usr/share/gnome-connection-manager/* .
ADD gcmconf /usr/local/bin/gcmconf
ADD startup.sh /src/misc/startup.sh
ADD iourc.sample /src/misc/iourc.txt
ADD gcm /usr/local/bin/gcm
# Set the locale


RUN cd /src && git clone https://github.com/GNS3/ubridge.git
RUN cd /src/ubridge && make 
# cannot  set capabilities on file in a build - must be resolv on run
RUN cd /src/ubridge && chmod +x ubridge && sudo cp ubridge /usr/local/bin/ubridge


RUN chmod a+x /src/misc/startup.sh
ENTRYPOINT cd /src/misc ; ./startup.sh
