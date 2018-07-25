#!/usr/bin/with-contenv bash

if [ "$DEBUG_MODE" = "TRUE" ] || [ "$DEBUG_MODE" = "true" ];  then
  set -x
fi

DATE=(`date "+%Y%m%d-%H%M%S"`)
FILENAME=$DATE-$LOGFILE
/gcds/sync-cmd -a -l ERROR -r /var/log/gcds/$FILENAME -c /gcds/gcds_conf.xml -o


if ls /assets/config/.syncState/*.lock >/dev/null 2>&1; then
LOCKFILE=`ls -C /assets/config/.SyncState/*.lock | sed "s~/assets/config/.syncState/~~g"`

	if [ `stat --format=%Y /assets/config/.syncState/$LOCKFILE` -le $(( `date +%s` - 1800 )) ]; then 
		/usr/local/bin/rocketchat-alert "#it-systems" "*Lockfile Issue*" "The Google Cloud Directory Sync seems to be hung due to a stale lockfile. I've deleted it, however this was after 30 minutes of hanging. Please monitor the container for any further issues.\n "  "gcds-app"\;
		rm -rf  /assets/config/.syncState/$LOCKFILE
	fi
fi;

if [ ! -s "/var/log/gcds/$FILENAME" ] ; then
    rm -rf /var/log/gcds/$FILENAME;
fi

if grep '[ERROR] [usersyncapp.sync.ConfigErrorHandler]' /tmp/$FILENAME ; then
	/usr/local/bin/rocketchat-alert "#it-systems" "*Synchronization Failed*" "The Google Cloud Directory Sync is reporting Fatal Errors. Please login to the host server, enter the GCDS container and troubleshoot. I think it's something to do with the OAUTH key. See the file */tmp/$FILENAME.error* for hints.\n "  "gcds-app"
	mv /tmp/$FILENAME /tmp/$FILENAME.error
fi

if grep '"LDAP Plugin" threw a fatal exception' /tmp/$FILENAME ; then
	/usr/local/bin/rocketchat-alert "#it-systems" "*Synchronization Failed*" "The Google Cloud Directory Sync is reporting Fatal Errors. Please login to the host server, enter the GCDS container and troubleshoot. I think it's something to do with improper LDAP Hostname, or Credentials. See the file */tmp/$FILENAME.error* for hints.\n "  "gcds-app"
	mv /tmp/$FILENAME /tmp/$FILENAME.error
fi

rm -rf /tmp/$FILENAME