#!/bin/sh

# Return error codes
# 0  - Success
# 40 - Generic RSYNC sync error
# 41 - Failed to create remote directory

. ./etc/rsync.config.sh
# RSYNC_USER="root"
# RSYNC_HOST="sisif"

RSYNC_DATE_START=$( date +%Y-%m-%d_%H-%M-%S )

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


function doRsync() {
	while IFS= read -r line; do
		if [[ "${line}" != '#'* ]]; then
			doBackupSinglePath "${line}";
		else
			echo "[WARN][RSYNC]: Ignoring commented backup path: ${line}";
		fi
	done < ./etc/backup-paths.txt
}

doRsync;
