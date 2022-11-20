#!/bin/bash

DRY_RUN=0
REMOTE_HOST=''
SYNC_ALL=0
SYNC_PROFILE=''

while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--dry-run)
        DRY_RUN=1
        shift
        ;;
    -a|--all)
        SYNC_ALL=1
        shift
        ;;
    -p|--profile)
        SYNC_PROFILE=$2
        shift
        shift
        ;;
    -h|--help)
        echo """
Usage: $0 [args] remote_host

Arguments:
    --dry-run: Run without copying any file
    -h|--help: Show this help
    remote_host: remote SSH host to sync the configurations from
        """
        exit 1
        ;;
    -*|--*)
        echo "Unknown option $1"
        exit 1
        ;;
    *)
        REMOTE_HOST=$1
        shift
        ;;
  esac
done

function rsync_with_filter() {
    local filter_path=$1
    local partial=$2
    local dryrun=$3
    local remote_host=$4

    echo "Running rsync with filter $filter_path for $remote_host"

    from_root="$(cat $filter_path | grep '#' | grep 'from_root' | awk -F 'from_root:' '{print $2}')"
    to_root="$(cat $filter_path | grep '#' | grep 'to_root' | awk -F 'to_root:' '{print $2}')"
    [[ $to_root == '' ]] && to_root=$from_root

    local command='rsync -am --progress'
    command="$command --filter='. $filter_path'"
    if [[ $partial -ne '0' ]]; then
        command="$command --partial"
    fi
    if [[ $dryrun -ne '0' ]]; then
        command="$command --dry-run"
    fi
    command="$command $remote_host:$from_root $to_root"

    echo $command
    eval $command
}

function run_rsync() {
    local script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    local profiles_dir="$script_dir/rsync_profiles"

    if [[ $SYNC_ALL -ne 0 ]]; then
        for profile in $(find $profiles_dir/*); do
            rsync_with_filter $profile 0 $DRY_RUN $REMOTE_HOST
        done
    else
        if [[ $SYNC_PROFILE == '' ]]; then
            echo "You must specific a sync_profile to proceed!"
            exit 1
        fi
        rsync_with_filter $SYNC_PROFILE 0 $DRY_RUN $REMOTE_HOST
    fi
}

run_rsync
