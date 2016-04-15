FROM debian:unstable

MAINTAINER Sysdig <support@sysdig.com>

ENV SYSDIG_REPOSITORY dev

ENV SYSDIG_HOST_ROOT /host

ENV HOME /root

RUN cp /etc/skel/.bashrc /root && cp /etc/skel/.profile /root

ADD http://download.draios.com/apt-draios-priority /etc/apt/preferences.d/

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash-completion \
    curl \
    ca-certificates \
    gcc \
    gcc-4.9 \
    gcc-4.8 \
    openjdk-8-jre-headless \
    python && rm -rf /var/lib/apt/lists/*

# Terribly terrible hacks: since our base Debian image ships with GCC 5.0 which breaks older kernels,
# revert the default to gcc-4.9. Also, since some customers use some very old distributions whose kernel
# makefile is hardcoded for gcc-4.6 or so (e.g. Debian Wheezy), we pretend to have gcc 4.6/4.7 by symlinking
# it to 4.8

RUN rm -rf /usr/bin/gcc \
 && ln -s /usr/bin/gcc-4.9 /usr/bin/gcc \
 && ln -s /usr/bin/gcc-4.8 /usr/bin/gcc-4.7 \
 && ln -s /usr/bin/gcc-4.8 /usr/bin/gcc-4.6

RUN curl -s https://s3.amazonaws.com/download.draios.com/DRAIOS-GPG-KEY.public | apt-key add - \
 && curl -s -o /etc/apt/sources.list.d/draios.list http://download.draios.com/$SYSDIG_REPOSITORY/deb/draios.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends draios-agent \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN ln -s $SYSDIG_HOST_ROOT/lib/modules /lib/modules

COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
