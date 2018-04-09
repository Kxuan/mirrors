#!/bin/bash

# This is a simple mirroring script. To save bandwidth it first checks a
# timestamp via HTTP and only runs rsync when the timestamp differs from the
# local copy. As of 2016, a single rsync run without changes transfers roughly
# 6MiB of data which adds up to roughly 250GiB of traffic per month when rsync
# is run every minute. Performing a simple check via HTTP first can thus save a
# lot of traffic.

# Directory where the repo is stored locally. Example: /srv/repo
target="${TARGET_DIR}"

# Directory where files are downloaded to before being moved in place.
# This should be on the same filesystem as $target, but not a subdirectory of $target.
# Example: /srv/tmp
tmp="${TMP_DIR}"

# If you want to limit the bandwidth used by rsync set this.
# Use 0 to disable the limit.
# The default unit is KiB (see man rsync /--bwlimit for more)
bwlimit="${BWLIMIT}"

# The source URL of the mirror you want to sync from.
# If you are a tier 1 mirror use rsync.archlinux.org, for example like this:
# rsync://rsync.archlinux.org/ftp_tier1
# Otherwise chose a tier 1 mirror from this list and use its rsync URL:
# https://www.archlinux.org/mirrors/
source_url='rsync://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/armv7h'

#### END CONFIG

[ ! -d "${target}" ] && mkdir -p "${target}"
[ ! -d "${tmp}" ] && mkdir -p "${tmp}"

rsync_cmd() {
	local -a cmd=(rsync -rtlHz --safe-links --delete-after ${VERBOSE} "--timeout=600" "--contimeout=60" -p \
		--delay-updates --no-motd "--temp-dir=${tmp}"
        --log-file="$LOG_FILE")

	if stty &>/dev/null; then
		cmd+=(-h -v --progress)
	else
		cmd+=(--quiet)
	fi

	if [[ -n $bwlimit ]]; then
		cmd+=("--bwlimit=$bwlimit")
	fi

	"${cmd[@]}" "$@"
}


rsync_cmd \
    --exclude-from='exclude.txt' \
    --exclude-from="${EXCLUDE_LIST}" \
	"${source_url}" \
	"${target}"
