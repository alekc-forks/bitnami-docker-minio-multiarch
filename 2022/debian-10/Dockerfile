ARG WAIT_FOR_PORT_VERSION=v1.0.3
ARG GOSU_VERSION=v1.14

FROM alpine as downloader
ARG TARGETARCH
ARG WAIT_FOR_PORT_VERSION
ARG GOSU_VERSION

WORKDIR /src
RUN apk add curl

# download waitforport
ADD https://github.com/bitnami/wait-for-port/releases/download/$WAIT_FOR_PORT_VERSION/wait-for-port-linux-$TARGETARCH.tar.gz .
RUN tar xzvf wait-for-port-linux-$TARGETARCH.tar.gz

#download gosu
RUN curl https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$TARGETARCH --output gosu
RUN chmod +x gosu

FROM docker.io/bitnami/minideb:buster
LABEL maintainer "Alexander Chernov <alexander@chernov.it>"

ARG TARGETARCH
ARG WAIT_FOR_PORT_VERSION
ARG MINIO_VERSION

ENV HOME="/" \
    OS_ARCH="$TARGETARCH" \
    OS_FLAVOUR="debian-10" \
    OS_NAME="linux"

COPY prebuildfs /
# Install required system packages and dependencies
RUN install_packages acl ca-certificates curl gzip jq libc6 procps tar
COPY --from=downloader /src/wait-for-port-linux-$TARGETARCH /opt/bitnami/common/bin/wait-for-port
COPY --from=downloader /src/gosu /opt/bitnami/common/bin/gosu

COPY --from=minio/mc:latest  /bin/mc /opt/bitnami/minio-client/bin/mc
COPY --from=minio/minio:latest  /opt/bin/minio /opt/bitnami/minio/bin/minio
RUN apt-get update && apt-get upgrade -y && \
    rm -r /var/lib/apt/lists /var/cache/apt/archives
RUN chmod g+rwX /opt/bitnami

COPY rootfs /
RUN /opt/bitnami/scripts/minio-client/postunpack.sh
RUN /opt/bitnami/scripts/minio/postunpack.sh
ENV APP_VERSION="$MINIO_VERSION" \
    BITNAMI_APP_NAME="minio" \
    WAIT_FOR_PORT_VERSION="$WAIT_FOR_PORT_VERSION" \
    GOSU_VERSION="$GOSU_VERSION" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/minio-client/bin:/opt/bitnami/minio/bin:$PATH"

VOLUME [ "/certs", "/data" ]

EXPOSE 9000 9001

WORKDIR /opt/bitnami/minio-client
USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/minio/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/minio/run.sh" ]
