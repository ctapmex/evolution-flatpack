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
        /src/org.gnome.Evolution.Local.flatpak 2>/dev/null || true
}
trap cleanup EXIT

# flatpak-builder cannot checksum a directory, so a "dir" source rebuilds every time.
# Publish the current tree, including uncommitted edits, as refs/flatpak/build.
# The ref moves only when the tree changes, and unchanged modules stay cached.
snapshot_tree() {
    local repo="$1"
    local index tree old oldtree commit
    index="$(mktemp)"
    (
        cd "$repo"
        export GIT_INDEX_FILE="$index"
        export GIT_AUTHOR_NAME=flatpak-build
        export GIT_AUTHOR_EMAIL=flatpak-build@local
        export GIT_COMMITTER_NAME=flatpak-build
        export GIT_COMMITTER_EMAIL=flatpak-build@local
        git read-tree HEAD
        git add -A -- .
        tree="$(git write-tree)"
        old="$(git rev-parse -q --verify refs/heads/flatpak-build || true)"
        if [ -n "$old" ]; then
            oldtree="$(git rev-parse "${old}^{tree}")"
            if [ "$oldtree" = "$tree" ]; then
                exit 0
            fi
        fi
        commit="$(git commit-tree "$tree" -m "flatpak build snapshot")"
        git update-ref refs/heads/flatpak-build "$commit"
    )
    rm -f "$index"
}

snapshot_tree /src/src/evolution-data-server
snapshot_tree /src/src/evolution
snapshot_tree /src/src/evolution-ews

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
