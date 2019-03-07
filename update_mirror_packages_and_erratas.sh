#!/bin/bash
#
# Description:
# This script calls 'do_reposync.sh' to update the local mirror. After that the script 'update_multiple_stages.sh' is called to update all configured stage repositories.
#
# When all local repos were updated the Red Hat Errata Information are downloaded from the web and added to the local repos. This way you could provide Red Hat Errata Information to systems which are not connected to the internet or using repos from local mirror only.
#
# Version: 1.0.0
# License: MIT copyright (c) 2016 Joerg Kastning <joerg.kastning(aet)uni-bielefeld(dot)de>
##############################################################################

# Variables ##################################################################
SCRIPTNAME=`basename ${0}`
PROGDIR=$(dirname $(readlink -f ${0}))
. $PROGDIR/CONFIG

# Functions #################################################################
remove_older_updateinfo()
{
  for REPO in "${REPOID[@]}"
    do
      /usr/bin/find ${BASEDIR}${REPO}/ -type f -mtime +1 -name "*updateinfo.xml.gz" -exec rm {} \;
  done
}
deploy_updateinfo()
{
  for REPO in "${REPOID[@]}"
    do
			for FILE in ${BASEDIR}${REPO}/*-updateinfo.xml.gz
				do
					[[ $FILE -nt $LATEST ]] && LATEST=$FILE
			done
      /usr/bin/rm ${BASEDIR}${REPO}/repodata/*updateinfo*
      /usr/bin/cp ${LATEST} ${BASEDIR}${REPO}/repodata/$TARGETGZFILENAME
      /usr/bin/gzip -d ${BASEDIR}${REPO}/repodata/$TARGETGZFILENAME
      /usr/bin/modifyrepo ${BASEDIR}${REPO}/repodata/$TARGETFILENAME ${BASEDIR}${REPO}/repodata/
			unset -v LATEST
			unset -v FILE
  done
}

# Main ##############################################################
echo \# `date +%Y-%m-%dT%H:%M` - Update Local Mirror \# > $LOG
bash $PROGDIR/do_reposync.sh >> $LOG 2>&1

echo "\n" >> $LOG
echo \# `date +%Y-%m-%dT%H:%M` - Implement Errata-Information \# >> $LOG
remove_older_updateinfo >> $LOG 2>&1
deploy_updateinfo >> $LOG 2>&1
echo "\n" >> $LOG
echo \# `date +%Y-%m-%dT%H:%M` - Update rhel-STAGE-repositories \# >> $LOG
bash $PROGDIR/update_multiple_stages.sh >> $LOG 2>&1
echo \# `date +%Y-%m-%dT%H:%M` - End of processing \# >> $LOG
# End ###############################################################
