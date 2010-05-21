#! /bin/sh

# Update script that copies plugin and feature files for Saros to sourceforge
# and automagically updates the required site.xml files for Eclipse in the
# process
#
# 2010 Florian Thiel <florian.thiel@fu-berlin.de> for the Saros project

### LOCATIONS, VARIABLES ###

BASEDIR="/home/build"
JARS_DIR="/var/lib/hudson/jobs/SarosTrunk/workspace/Saros/build/uninstrumented"
LOCAL_TEMP_DIR="$BASEDIR/buildtemp"
SF_USER="florianthiel" 
SF_KEY_FILE="$BASEDIR/UpdateSiteTools/saros-build-flo"
SF_FRS_TARGET_DIR="${SF_USER},dpp@frs.sourceforge.net:/home/frs/project/d/dp/dpp/saros"
SF_UPDATE_SITE_TARGET_DIR="${SF_USER},dpp@web.sourceforge.net:/home/groups/d/dp/dpp/htdocs"
SF_UPDATE_SITE_DIR_NAME="update-devel"

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

echo "Creating/updating site.xml"
./updateSiteXML.py $SF_UPDATE_SITE_DIR_NAME/site.xml "$LOCAL_TEMP_DIR/DPP $VERSION/"
UPDATE_SITE_RETURN=$?

if [ $UPDATE_SITE_RETURN -eq 1 ]; then
    echo "Running site update script failed, look at output"
    exit 1
elif [ $UPDATE_SITE_RETURN -eq 2 ]; then
    echo "site.xml is up to date, no need for updating files. Exiting!"
    exit 0
fi

echo "updating feature/plugin @ Sourceforge"
rsync -a -v -e ssh --exclude .svn "$LOCAL_TEMP_DIR/DPP $VERSION" "$SF_FRS_TARGET_DIR"
echo "updating update site @ Sourceforge"
rsync -a -v -e ssh --exclude .svn "$SF_UPDATE_SITE_DIR_NAME" "$SF_UPDATE_SITE_TARGET_DIR"

### Cleanup ###
echo "Cleaning temporary local dirs"
rm -rf $LOCAL_TEMP_DIR
