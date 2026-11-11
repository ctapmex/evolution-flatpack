#!/bin/bash
# Build org.gnome.Evolution.Local.flatpak in an Ubuntu 24.04 container.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p cache/flatpak cache/flatpak-builder build repo

# The account is in the docker group, so the daemon is reachable without sudo.
docker build -t evolution-builder "$ROOT/docker"

docker run --rm --privileged \
    --device /dev/fuse \
    -v "$ROOT":/src \
    -v "$ROOT/cache/flatpak":/var/lib/flatpak \
    evolution-builder \
    bash /src/docker/build-inside.sh
