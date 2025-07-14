FROM ubuntu:24.04 as gobuild

WORKDIR /build
RUN apt-get update && apt install -y golang ca-certificates
ADD go.mod go.sum /build/
ADD cmd /build/cmd
ADD pkg /build/pkg
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver

FROM ubuntu:24.04
LABEL maintainers="Vitaliy Filippov <vitalif@yourcmc.ru>"
LABEL description="csi-s3 slim image"
RUN apt-get update
RUN apt-get install -y fuse3 mailcap rclone git meson ninja-build
RUN git clone https://github.com/wangrzneu/libfuse.git
RUN cd libfuse && mkdir build && cd build && meson setup .. && ninja && ninja install && cd ../../
RUN apt-get install -y autoconf autotools-dev openjdk-21-jre-headless jq libcurl4-openssl-dev libxml2-dev locales-all mailcap libtool pkg-config libssl-dev attr curl python3-pip unzip
RUN git clone https://github.com/wangrzneu/s3fs-fuse.git 
RUN cd s3fs-fuse && ./autogen.sh && ./configure --prefix=/usr --with-openssl &&  make --jobs=4 && make install
ADD https://github.com/yandex-cloud/geesefs/releases/latest/download/geesefs-linux-amd64 /usr/bin/geesefs
RUN chmod 755 /usr/bin/geesefs
RUN apt clean && apt autoremove

COPY --from=gobuild /build/s3driver /s3driver
ENTRYPOINT ["/s3driver"]
