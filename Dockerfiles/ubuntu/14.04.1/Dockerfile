# Provides Ubuntu 14.04.1 with a real name

FROM switch/baseimage

MAINTAINER Anurag Priyam <anurag08priyam@gmail.com>

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      wget python software-properties-common && \
    apt-get clean

RUN add-apt-repository universe && \
    add-apt-repository multiverse && \
    apt-get update

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
      dictionaries-common aspell aspell-en hunspell-en-us libenchant1c2a:amd64 \
      libwebkitgtk-3.0-0:amd64 enchant libyelp0 yelp gnome-user-guide zenity \
      unity-control-center unity-control-center-signon indicator-bluetooth
    apt-get clean

