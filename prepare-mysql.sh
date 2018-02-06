#!/usr/bin/env bash

#
# 30 - Generic MySQL dump error
# 31 - Failed to meet prerequisites

. ./etc/config.sh

function mysqlPrerequisites() {
	mysql -u root -p${MYSQL_PASSWORD} -e "USE mysql"
	if [ $? -ne 0 ]; then
		echo "[ERROR][MYSQL]: Failed to validate connection!";
		return 32
	fi
}

#
# Make a list of the databases and dump them
#
function mysqlBackupDatabases() {
	ret=0
	for database in $(mysql -u root -B --disable-column-names -e "SHOW DATABASES"); do
		if [ ${database} != "performance_schema" ] && [ ${database} != "information_schema" ]; then
			dump_file="${MYSQL_DUMP_PATH}/${database}.sql.gz"
			mysqldump -u root -p${MYSQL_PASSWORD} "${database}" | gzip > "${dump_file}"
			if [ $? -ne 0 ]; then
				echo "[ERROR][MYSQL]: Failed to dump database ${database}, aborting!";
				return 32
			else
				echo "[INFO][MYSQL]: Successfully dumped ${database}";
			fi
		fi
	done
}

#
# Main function.
#
function mysqlMain() {
	mysqlPrerequisites;	
	if  [ $? -ne 0 ]; then
		echo "[CRITICAL][MYSQL]: Failed to meet prerequisites, aborting!";
		return 31
	fi
	mysqlBackupDatabases;
}

mysqlMain;