#!/bin/bash
# Runs inside the Ubuntu 24.04 builder container.
set -euo pipefail

cd /src

# The cache is owned by the host user, while this container runs as root.
git config --global --add safe.directory '*'
git config --global protocol.file.allow always

# The container runs as root. Hand build artifacts back to the directory owner.
# The GNOME SDK in /src/cache/flatpak stays as it is: chown of that tree is most of the wait.
cleanup() {
    local owner
    owner="$(stat -c '%u:%g' /src)"
    chown -R "$owner" \
        /src/repo \
        /src/build \
        /src/cache/flatpak-builder \
        /src/.git/modules \
        /src/src/evolution/.git \
        /src/src/evolution-data-server/.git \
        /src/src/evolution-ews/.git \
        /src/org.gnome.Evolution.Local.flatpak 2>/dev/null || true
}
trap cleanup EXIT

# flatpak-builder checks out the branch named in the manifest, not HEAD
# and not uncommitted files. local-3.62 is the integration branch.
for repo in evolution-data-server evolution evolution-ews; do
    if [ -n "$(git -C "/src/src/$repo" status --porcelain)" ]; then
        echo "В $repo есть несохранённые правки. Сборка берёт коммит ветки из манифеста." >&2
    fi
    git -C "/src/src/$repo" log -1 --oneline local-3.62
done

if ! flatpak remotes | grep -q '^flathub'; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

flatpak install -y flathub org.gnome.Platform//50 org.gnome.Sdk//50

export CCACHE_MAXSIZE=8G

flatpak-builder \
    --disable-rofiles-fuse \
    --ccache \
    --force-clean \
    --repo=/src/repo \
    --state-dir=/src/cache/flatpak-builder \
    /src/build \
    /src/packaging/org.gnome.Evolution.json

flatpak build-bundle \
    /src/repo \
    /src/org.gnome.Evolution.Local.flatpak \
    org.gnome.Evolution.Local
