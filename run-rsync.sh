#!/bin/sh

# Return error codes
# 0  - Success
# 40 - Generic RSYNC sync error
# 41 - Failed to create remote directory
# 42 - Failed to validate SSH connection

. ./etc/rsync.config.sh
# RSYNC_USER="root"
# RSYNC_HOST="sisif"

RSYNC_DATE_START=$( date +%Y-%m-%d_%H-%M-%S )

function rsyncPrerequisites() {
	ssh ${RSYNC_USER}@${RSYNC_HOST} rm -rf ~/.test && touch ~/.test
	if [ ! $? -eq 0 ]; then
		echo "[CRITICAL][RSYNC]: Failed to validate remote connection: ${RSYNC_USER}@${RSYNC_HOST}";
		exit 42
	fi
	return 0
}

# Receive backup path and try to sync
function doBackupSinglePath() {
	ret=0
	src_path="$(cut -d':' -f1 <<< $1)"
	dest_path="$(cut -d':' -f2 <<< $1)"
	ssh ${RSYNC_USER}@${RSYNC_HOST} "mkdir -p ${dest_path}" < /dev/null
	if [ ! $? -eq 0 ]; then
		echo "[CRITICAL][RSYNC]: Failed to create remote directory: ${dest_path}";
		ret=41
	else
		log_path="${RSYNC_TMP}/rsync-${RSYNC_DATE_START}.log"
		rsync --delete --log-file="${log_path}" --log-file-format='%o: %B %f %L %l %b' --rsync-path='rsync --fake-super' -avAX --exclude-from='./etc/backup-excludes.txt' "${src_path}" ${RSYNC_USER}@${RSYNC_HOST}:${dest_path}
	fi

	return ${ret}
}

# Parse backup-paths.txt and read the path to backup
function doRsync() {
	while IFS= read -r line; do
		if [[ "${line}" != '#'* ]] && [ ! -z "${line}" ]; then
			doBackupSinglePath "${line}";
		else
			if [ ! -z "${line}" ]; then
				echo "[WARN][RSYNC]: Ignoring commented or empty backup path: ${line}";
			fi
		fi
	done < ./etc/backup-paths.txt
}

rsyncPrerequisites;
doRsync;
