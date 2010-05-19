#! /bin/sh

# LOCATIONS, VARIABLES

JARS_DIR="/var/lib/hudson/jobs/SarosFeatureTrunk/workspace/Saros/build/uninstrumented"
LOCAL_TEMP_DIR="$HOME/buildtemp"
SF_USER="florianthiel"
SF_FRS_TARGET_DIR="${SF_USER},dpp@frs.sourceforge.net:/home/frs/project/d/dp/dpp/saros"
SF_UPDATE_SITE_TARGET_DIR="${SF_USER},dpp@web.sourceforge.net:/home/groups/d/dp/dpp/"

### FRS ###

# prepare local directory for FRS (file distribution)

mkdir -p "$LOCAL_TEMP_DIR"
VERSION=`ls $JARS_DIR/features/de.fu_berlin.inf.dpp.feature* | perl -pe 's/.*de\.fu\_berlin\.inf\.dpp\.feature\_(.*)\.jar/\1/'`
echo $VERSION
mkdir -p "$LOCAL_TEMP_DIR/DPP $VERSION"
cp -a $JARS_DIR/features/*.jar "$LOCAL_TEMP_DIR/DPP $VERSION/"
cp -a $JARS_DIR/plugins/*.jar "$LOCAL_TEMP_DIR/DPP $VERSION/"

rsync -av -e ssh "$LOCAL_TEMP_DIR/DPP $VERSION" "$SF_FRS_TARGET_DIR"

### Update Site ###



### Cleanup ###
#rm -rf $LOCAL_TEMP_DIR

