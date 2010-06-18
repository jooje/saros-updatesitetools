#! /bin/sh

# VERSION FOR UPDATING STABLE RELEASES!
# Update script that copies plugin and feature files for Saros to sourceforge
# and automagically updates the required site.xml files for Eclipse in the
# process
#
# NOTE: This is the version to to stable releases! Apart from some paths
# being different, the major difference is that running the script when
# there's no new version results in an error!
#
# 2010 Florian Thiel <florian.thiel@fu-berlin.de> for the Saros project

### LOCATIONS, VARIABLES ###

set -e

BASEDIR="/home/build"
JARS_DIR="/var/lib/hudson/jobs/BuildSarosRelease/workspace/Saros/build/uninstrumented"
LOCAL_TEMP_DIR="$BASEDIR/buildtempStable"
SF_USER="k_beecher" 
SF_KEY_FILE="$BASEDIR/UpdateSiteTools/saros-build.key"
SF_FRS_TARGET_DIR="${SF_USER},dpp@frs.sourceforge.net:/home/frs/project/d/dp/dpp/saros"
SF_UPDATE_SITE_TARGET_DIR="${SF_USER},dpp@web.sourceforge.net:/home/groups/d/dp/dpp/htdocs"
SF_UPDATE_SITE_DIR_NAME="update-releases"

### Functions ###
cleanup ()
{
	echo "Cleaning temporary local dirs"
	rm -rf $LOCAL_TEMP_DIR
	kill $SSH_AGENT_PID
};

### MAIN ###

echo -n "I'm running with UID "
echo `id`

### SET USER KEY ###
eval `ssh-agent`
# the key file must have been imported through sf's web interface, beforehand
ssh-add $SF_KEY_FILE

### FRS ###

# prepare local directory for FRS (file distribution)

echo "Setting up temporary local dir"
mkdir -p "$LOCAL_TEMP_DIR"
VERSION=`ls $JARS_DIR/features/de.fu_berlin.inf.dpp.feature* | perl -pe 's/.*de\.fu\_berlin\.inf\.dpp\.feature\_(.*)\.jar/\1/'`
echo $VERSION
mkdir -p "$LOCAL_TEMP_DIR/DPP $VERSION"
cp -a $JARS_DIR/features/*.jar "$LOCAL_TEMP_DIR/DPP $VERSION/"
cp -a $JARS_DIR/plugins/*.jar "$LOCAL_TEMP_DIR/DPP $VERSION/"

### Update Site ###
# Run site.xml updater script, determines if we need updating (returns 2)
# need +e to prevent shell from exiting without proper error message

set +e
echo "Creating/updating site.xml"
./updateSiteXML.py $SF_UPDATE_SITE_DIR_NAME/site.xml "$LOCAL_TEMP_DIR/DPP $VERSION/"
UPDATE_SITE_RETURN=$?
set -e

if [ $UPDATE_SITE_RETURN -eq 1 ]; then
    echo "Running site update script failed, look at output"
    cleanup
    exit 1
elif [ $UPDATE_SITE_RETURN -eq 2 ]; then
    echo "site.xml is up to date, no need for updating files. Exiting!"
    cleanup
    exit 1
fi

set +e
echo "updating feature/plugin @ Sourceforge"
rsync -a -v -e "ssh -o UserKnownHostsFile=$BASEDIR/.ssh/known_hosts" --exclude .svn "$LOCAL_TEMP_DIR/DPP $VERSION" "$SF_FRS_TARGET_DIR"
UPDATE_JARS_RETURN=$?
set -e

if [ $UPDATE_JARS_RETURN -ne 0 ]; then
	echo "Updating JARs failed. Aborting update"
        cleanup
	exit 1
fi

# everything went fine till now, replace old site.xml now

mv "$SF_UPDATE_SITE_DIR_NAME/site.xml.new" "$SF_UPDATE_SITE_DIR_NAME/site.xml"

# WARNING: If this fails, this script will not attempt to update again because the local file has already been updated
echo "updating update site @ Sourceforge"
rsync -a -v -e "ssh -o UserKnownHostsFile=$BASEDIR/.ssh/known_hosts" --exclude .svn "$SF_UPDATE_SITE_DIR_NAME" "$SF_UPDATE_SITE_TARGET_DIR"

cleanup
