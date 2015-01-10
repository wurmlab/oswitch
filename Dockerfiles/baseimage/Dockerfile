FROM ubuntu:14.04.1
MAINTAINER Anurag Priyam <anurag08priyam@gmail.com>

RUN echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf && \
    echo 'APT::Install-Suggests "false";' >> /etc/apt/apt.conf && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      zsh fish && \
    apt-get clean && \
    locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

COPY wheel /etc/sudoers.d/
COPY _init /usr/local/bin/

ENTRYPOINT ["_init"]

