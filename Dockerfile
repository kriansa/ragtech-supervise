FROM docker.io/library/debian:trixie-slim AS build
ARG SUPERVISE_VERSION=8.9-2

RUN apt-get update && apt-get install -y curl

RUN mkdir /root/supervise
WORKDIR /root/supervise

RUN curl -o supervise.sh https://ragtech.com.br/Softwares_download/supervise-${SUPERVISE_VERSION}.sh
RUN chmod +x ./supervise.sh && ./supervise.sh --tar xpvf .
RUN dpkg-deb -xv Supervise.deb pkg
RUN mkdir /opt/supervise

# Copy only required files for supervise to work -- no fluff.
RUN for file in config.so device.so devices.xml monit.cfg monit.so supsvc web; do \
    cp -r /root/supervise/pkg/opt/supervise/$file /opt/supervise/; \
  done

FROM docker.io/library/debian:trixie-slim

# supsvc only requires these packages below
RUN apt-get update && apt-get upgrade --yes && \
  apt-get install -y libqt5core5a libqt5script5 libqt5sql5 sqlite3 udev procps && \
  apt-get clean autoclean && apt-get autoremove --yes && rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY --from=build /opt/supervise /opt/supervise
COPY init.sh /init.sh

EXPOSE 4470
VOLUME /data
ENTRYPOINT ["/init.sh"]
