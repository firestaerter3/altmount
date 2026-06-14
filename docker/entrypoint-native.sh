#!/bin/sh
# Minimal s6-free entrypoint for the native-FUSE altmount image.
#
# Under `userns_mode: host` the container is NOT uid-remapped, so PUID/PGID are
# REAL host ids. Realign the abc account to them (so $HOME and any name lookups
# resolve), make sure the data dirs are owned by that id, then drop privileges.
set -eu

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

if [ "$(id -u abc 2>/dev/null || echo -1)" != "$PUID" ] || \
   [ "$(id -g abc 2>/dev/null || echo -1)" != "$PGID" ]; then
    groupmod -o -g "$PGID" abc 2>/dev/null || groupadd -o -g "$PGID" abc
    usermod -o -u "$PUID" -g "$PGID" abc
fi

# Own the persistent dirs (best-effort; a read-only bind shouldn't abort start).
chown "$PUID:$PGID" /config /metadata 2>/dev/null || true

exec gosu abc /app/altmount serve --config=/config/config.yaml
