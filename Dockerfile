FROM ubuntu:16.04

ARG APT_KEY="http://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0xFC8A16625AFA7A83"
ARG APT_REPO="deb [arch=amd64] http://ubuntu.openvidu.io/dev xenial kms6"
ARG CACHE_BUST=1
ARG BUILD_TOOLS="build-essential gdb pkg-config cmake \
  clang debhelper valgrind \
  git wget maven openjdk-[8|7]-jdk \
  software-properties-common apt-transport-https"
ARG BUILD_DEPENDENCIES="libboost-dev \
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
  uuid-dev \
  libgstreamer1.5-dev \
  libgstreamer-plugins-base1.5-dev \
  libnice-dev \
  openwebrtc-gst-plugins-dev \
  kmsjsoncpp-dev \
  ffmpeg"
ARG RUNTIME_DEPENDENCIES="curl \
  jq \
  libxml2-utils \
  gstreamer1.5-libav \
  gstreamer1.5-nice \
  gstreamer1.5-plugins-bad \
  gstreamer1.5-plugins-base \
  gstreamer1.5-plugins-good \
  gstreamer1.5-plugins-ugly \
  gstreamer1.5-x \
  libsigc++-2.0-0v5 \
  libglibmm-2.4-1v5 \
  libboost-program-options1.58.0 \
  libboost-thread1.58.0 \
  libboost-log1.58.0 \
  kmsjsoncpp \
  openwebrtc-gst-plugins \
  openh264-gst-plugins-bad-1.5"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
  $BUILD_TOOLS \
 && wget "$APT_KEY" -O- | apt-key add - \
 && add-apt-repository "$APT_REPO" \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
  $BUILD_DEPENDENCIES \
  $RUNTIME_DEPENDENCIES \
 && useradd -m -G users -s /bin/bash kurento

COPY . /source

RUN mv /source/docker-entrypoint.sh /usr/local/bin/ \
 && mv /source/healthchecker.sh /healthchecker.sh \
 && mkdir /app \
 && cd /app \
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_VERBOSE_MAKEFILE=ON /source \
 && make \
 && make install \
 && rm -rf /source /app \
 && apt-get -y purge $BUILD_TOOLS $BUILD_DEPENDENCIES \
 && apt-get -y autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf ~/.m2 \
 # Remove ipv6 local loop until ipv6 is supported
 && cat /etc/hosts | sed '/::1/d' | tee /etc/hosts > /dev/null \
 && chown -R kurento:kurento /usr/local/etc/kurento

USER kurento

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

CMD ["/usr/local/bin/kurento-media-server", "--modules-path=/usr/local/lib/", "--modules-config-path=/usr/local/etc/kurento/modules/kurento/", "--conf-file=/usr/local/etc/kurento/kurento.conf.json", "--gst-plugin-path=/usr/local/lib/gstreamer-1.5/"]

