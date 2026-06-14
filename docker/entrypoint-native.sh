#!/bin/sh
# s6-free entrypoint for the native-FUSE altmount image.
#
# Runs as ROOT on purpose. Under `userns_mode: host` (which this image exists to
# enable) the container is NOT uid-remapped, so container root == real host root
# — and real root is what can create the FUSE mount in the host namespace and
# write the mountpoint. rclone presents file ownership via its own uid/gid.
set -eu

# On a userns-remap docker daemon, image root-owned files are stored on disk as
# the remapped uid (e.g. 165536). Under userns_mode: host the container sees
# that un-remapped, so fusermount3 looks setuid-to-165536 — a non-real-root that
# cannot perform the privileged mount (fusermount: Operation not permitted).
# Re-anchor the mount helpers to real root so the mount succeeds.
for helper in /usr/bin/fusermount3 /usr/bin/fusermount /bin/fusermount3 /bin/fusermount; do
    if [ -e "$helper" ]; then
        chown 0:0 "$helper" 2>/dev/null || true
        chmod u+s "$helper" 2>/dev/null || true
    fi
done

exec /app/altmount serve --config=/config/config.yaml
