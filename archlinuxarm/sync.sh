#!/bin/bash

# This is a simple mirroring script. To save bandwidth it first checks a
# timestamp via HTTP and only runs rsync when the timestamp differs from the
# local copy. As of 2016, a single rsync run without changes transfers roughly
# 6MiB of data which adds up to roughly 250GiB of traffic per month when rsync
# is run every minute. Performing a simple check via HTTP first can thus save a
# lot of traffic.

# Directory where the repo is stored locally. Example: /srv/repo
target="${TARGET_DIR}"

# The source URL of the mirror you want to sync from.
# If you are a tier 1 mirror use rsync.archlinux.org, for example like this:
# rsync://rsync.archlinux.org/ftp_tier1
# Otherwise chose a tier 1 mirror from this list and use its rsync URL:
# https://www.archlinux.org/mirrors/
source_url='rsync://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/armv7h'

#### END CONFIG

[ ! -d "${target}" ] && mkdir -p "${target}"

rsync_cmd() {
	local -a cmd=(rsync "${RSYNC_ARGS[@]}")

	if stty &>/dev/null; then
		cmd+=(-h -v --progress)
	else
		cmd+=(--quiet)
	fi

	"${cmd[@]}" "$@"
}


rsync_cmd \
    --exclude-from='exclude.txt' \
	"${source_url}" \
	"${target}"
