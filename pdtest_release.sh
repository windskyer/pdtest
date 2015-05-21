#!/usr/bin/env bash 
#author leidong

TOP_DIR=$(cd $(dirname "$0")/ && pwd)

ETC_DIR=${TOP_DIR}/etc
UNIT_DIR=${TOP_DIR}/unit
CLIENT_DIR=${TOP_DIR}/client
SERVICE_DIR=${TOP_DIR}/service
SDIST_DIR=${TOP_DIR}/sdist



OBJECT_NAME=${OBEJCT_NAME:-"pdtest"}
OBJECT_VERSION=${OBJECT_VERSION:-"2.5"}

CMD_SVN=$(which svn)
if [[ $? -ne 0 || ! -n $CMD_SVN ]] ; then
    echo "Not Found svn commond " 
    exit 1 
fi

[[ ! -d $CLIENT_DIR ]] && mkdir -p $CLIENT_DIR
[[ -d $SDIST_DIR ]] && rm -fr $SDIST_DIR
mkdir -p $SDIST_DIR

## get svn_url value
. $UNIT_DIR/functions
ARGS_FILE=$ETC_DIR/pdclient.conf

if [[ ! -f  $ARGS_FILE ]] ; then 
    echo "Not Found $ARGS_FILE file" 
    exit 2 
fi

get_args_conf default $ARGS_FILE SVN_URL OUTARGS

SVN_URL=${OUTARGS:="http://172.24.23.246:81/svn/PowerCenter/PowerCenter/branches/dev/PD-SRC-Dev2.5.4/scripts"}
## svn update script

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

exclude="LICENSE\nChangeLog\nAUTHORS\nMANIFEST.in\n\log\n.git\n.gitignore\n"
compress_object $exclude


