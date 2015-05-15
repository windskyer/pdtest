#!/usr/bin/env bash 
#author leidong

TOP_DIR=$(cd $(dirname "$0")/ && pwd)

ETC_DIR=${TOP_DIR}/etc
UNIT_DIR=${TOP_DIR}/unit
CLIENT_DIR=${TOP_DIR}/client
SERVICE_DIR=${TOP_DIR}/service
DIST_DIR=${TOP_DIR}/dist
SVN_URL="http://172.24.23.246:81/svn/PowerCenter/PowerCenter/branches/dev/PD-SRC-Dev2.5.4/scripts"
OBJECT_NAME=${OBEJCT_NAME:-"pdtest"}
OBJECT_VERSION=${OBJECT_VERSION:-"2015.5.1"}

[[ ! -d $CLIENT_DIR ]] && mkdir -p $CLIENT_DIR
[[ -d $DIST_DIR ]] && rm -fr $DIST_DIR
mkdir -p $DIST_DIR

## svn update script
CMD_SVN=$(which svn)
[[ $? -ne 0 || ! -n $CMD_SVN ]] && ( echo "Not Found svn commond " ; exit 1 )
if [[ -d $CLIENT_DIR/.svn ]]; then
    cd $CLIENT_DIR
    OUT_URL=$($CMD_SVN info | sed -n 's/^URL: \(.*\)/\1/p')
    if [[ $OUT_URL = $SVN_URL ]]; then
        $CMD_SVN up
        [[ $? -ne 0 ]] && ( echo "Not update svn script " ; exit 2 )
    else
        rm -fr $CLIENT_DIR/
        $CMD_SVN co $SVN_URL $CLIENT_DIR/
        [[ $? -ne 0 ]] && ( echo "Not update svn script " ; exit 2 )
    fi
    
else
    rm -fr $CLIENT_DIR/
    $CMD_SVN co $SVN_URL $CLIENT_DIR/
    [[ $? -ne 0 ]] && ( echo "Not update svn script " ; exit 2 )
fi

## tar pdtest obejct
cd $TOP_DIR
tar -czf `basename $DIST_DIR`/${OBJECT_NAME}-${OBJECT_VERSION}.tar `basename $CLIENT_DIR` `basename $SERVICE_DIR` `basename $UNIT_DIR` `basename $ETC_DIR` pdtest.sh
