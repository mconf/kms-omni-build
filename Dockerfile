FROM ubuntu:16.04

ARG APT_KEY="http://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0xFC8A16625AFA7A83"
ARG APT_REPO="deb [arch=amd64] http://ubuntu.openvidu.io/dev xenial kms6"

ARG CACHE_BUST=1

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
  build-essential gdb pkg-config cmake \
  clang debhelper valgrind \
  git wget maven 'openjdk-[8|7]-jdk' \
 && apt-get install -y --no-install-recommends \
  software-properties-common apt-transport-https \
  jq \
 && wget "$APT_KEY" -O- | apt-key add - \
 && add-apt-repository "$APT_REPO" \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
  libboost-dev \
  libboost-filesystem-dev \
  libboost-log-dev \
  libboost-program-options-dev \
  libboost-regex-dev \
  libboost-system-dev \
  libboost-test-dev \
  libboost-thread-dev \
  libevent-dev \
  libglib2.0-dev \
  libglibmm-2.4-dev \
  libopencv-dev \
  libsigc++-2.0-dev \
  libsoup2.4-dev \
  libssl-dev \
  libvpx-dev \
  libxml2-utils \
  uuid-dev \
 && apt-get install -y --no-install-recommends \
  gstreamer1.5-libav \
  gstreamer1.5-nice \
  gstreamer1.5-plugins-bad \
  gstreamer1.5-plugins-base \
  gstreamer1.5-plugins-good \
  gstreamer1.5-plugins-ugly \
  gstreamer1.5-x \
  libgstreamer1.5-dev \
  libgstreamer-plugins-base1.5-dev \
  libnice-dev \
  openwebrtc-gst-plugins-dev \
  kmsjsoncpp-dev \
  ffmpeg \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY . /source

RUN mkdir /app \
 && cd /app \
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_VERBOSE_MAKEFILE=ON /source \
 && make \
 && mv /source/docker-entrypoint.sh /usr/local/bin/ \
 && mv /source/healthchecker.sh /healthchecker.sh \
 # convert all links from /source to files
 && find /app/config -type l -exec bash -c 'cp --remove-destination "$(readlink -m "$0")" "$0"' {} \; \
 && rm -rf /source \
 # Remove ipv6 local loop until ipv6 is supported
 && cat /etc/hosts | sed '/::1/d' | tee /etc/hosts > /dev/null

ENV GST_DEBUG=Kurento*:5
ENV PORT=8888
# stun.l.google.com
ENV STUN_IP=64.233.186.127
ENV STUN_PORT=19302
ENV TURN_URL=""
ENV RTP_MIN_PORT=24577
ENV RTP_MAX_PORT=32768

HEALTHCHECK --start-period=15s --interval=30s --timeout=3s --retries=1 CMD /healthchecker.sh

WORKDIR /app
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["kurento-media-server/server/kurento-media-server", "--modules-path=.", "--modules-config-path=./config", "--conf-file=./config/kurento.conf.json", "--gst-plugin-path=."]
