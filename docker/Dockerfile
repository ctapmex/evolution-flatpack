FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        appstream \
        bzip2 \
        ca-certificates \
        elfutils \
        flatpak \
        flatpak-builder \
        fuse3 \
        git \
        librsvg2-common \
        ostree \
        patch \
        python3 \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
