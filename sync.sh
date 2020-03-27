#!/bin/bash

cd $(dirname $0)

root=/data/lib/mirrors
retry=1
repos=(*)
rsync_args="-rtlHp
    --safe-links
    --delete-after
    --timeout=600
    --contimeout=60
    --delay-updates
    --no-motd
    --max-size=10m
    --bwlimit=1m
    --exclude-from=$PWD/exclude.txt
"
log_rotate() {
    size=100m
    f="$1"

    [[ -z $(du -t $size "$f") ]] && return

    for (( i=0;;i++ )); do
        [[ ! -f "$f.$i" ]] && break
    done

    for ((;i>0;i--)); do
        mv -n "$f.$((i-1))" "$f.$i" || return
    done
    mv -n "$f" "$f.0"
}

do_sync_one() {
    set -e
    export DISTRO="$1"

    export TARGET_DIR="$root/$DISTRO"
    export TMP_DIR="$root/.tmp/$DISTRO"
    export LOG_DIR="$root/.log/$DISTRO"
    export LOG_FILE="$LOG_DIR/sync.log"
    export RSYNC_ARGS=( ${rsync_args} --temp-dir="$TMP_DIR" --log-file="$LOG_FILE" )

    (
        flock 9 || exit 5

        mkdir -p "$TMP_DIR" "$TARGET_DIR" "$root/.lock" "$LOG_DIR"
        log_rotate "$LOG_FILE"
        touch "$LOG_FILE"
        source ./sync.sh
    ) 9> "$root/.lock/$DISTRO.lock"
}

do_sync_all() {
    local repo
    fail=()
    for repo; do
        [[ ! -x "$repo/sync.sh" ]] && continue
        if ! pushd "$repo" >/dev/null; then
            echo "Can not enter dir $repo"
            continue
        fi

        echo "Syncing $repo"
        if ! su http -s /bin/bash -c "do_sync_one '$repo'" ; then
             echo "$repo failed"
             fail+=("$repo")
        fi

        popd >/dev/null
    done

    return ${#fail[@]}
}

export root rsync_args
export -f do_sync_one log_rotate

echo "Start syncing..."
fail=()
while ! do_sync_all "${repos[@]}" && [[ $retry -gt 0 ]]; do
    let retry--
    repos=( "${fail[@]}" )
    echo "Retry sync ${repos[@]}"
done
