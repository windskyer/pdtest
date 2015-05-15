#!/usr/bin/env ksh
#author leidong

TOP_DIR=$(cd $(dirname "$0")/ && pwd)
ETC_DIR=${TOP_DIR}/etc
UNIT_DIR=${TOP_DIR}/unit
LOG_DIR=${TOP_DIR}/log
CLIENT_DIR=${TOP_DIR}/client
SERVICE_DIR=${TOP_DIR}/service

SCRIPT_FILE=$ETC_DIR/pdserver.conf
ARGS_FILE=$ETC_DIR/pdclient.conf


[[ -f $UNIT_DIR/functions-common ]] && . $UNIT_DIR/functions-common || ( echo "Not Found functions-common file"; exit 1 )
[[ -f $SERVICE_DIR/test_script ]] && . $SERVICE_DIR/test_script || die $LINENO "Not Found test_script file"

function usage {
    printf "Usage:\n %s  <options>
    \t-d <script dir>         eg: -d client
    \t-f <script fullnames>   eg: -f get_host_info.sh
    \t-n <script names>       eg: -n getinfo
    \t-s <script subnames>    eg: -s host
    \t-v <script version>     eg: -v v2.0
    \t-A exec all shell script
    \t-F exec all [shell] group script
    \t-H or -h or -? Output hellp info \n" $(basename $0 | cut -d'.' -f1) >&2
    exit 1
}

Aflag=0
Fflag=0
dflag=0
fflag=0
nflag=0
sflag=0
vflag=0

## get commond args
while getopts 'AFf:d:n:s:v:h' OPTION
do
    case $OPTION in
        A)  Aflag=1
            ;;
        F)  Fflag=1
            ;;

        d)  dflag=1
            dirnames="$OPTARG"
            ;;

        f)  fflag=1
            fullscriptnames=" $fullscriptnames $OPTARG"
            ;;

        n)  nflag=1
            scriptnames=" $scriptnames $OPTARG"
            ;;

        s)  sflag=1
            subscriptnames="$subscriptnames $OPTARG"
            ;;

        v)  vflag=1
            scriptversions="$scriptversions $OPTARG"
            ;;

        h)  usage
            ;;

        ?)  usage
            ;;
    esac
done

## Set script dir 
if [[ $dflag -eq 1 ]]; then
    if [[ -n $dirnames ]] ; then
        CLIENT_DIR=${TOP_DIR}/$dirnames
        info $LINENO "scritp dir is $CLIENT_DIR"
    fi
fi

## exec all script shell files
if [[ $Aflag -eq 1 ]]; then
    info $LINENO "Will exec all script shell files"
    all_main
else
    ## exec [shell] group fullname script shell files
    if [[ $fflag -eq 1 ]] ; then
        info $LINENO "Will exec [shell] group $fullscriptnames script shell files"
        full_main "$fullscriptnames"
    fi

    ## exec [shell] group all script shell files
    if [[ $Fflag -eq 1 ]] ; then
        info $LINENO "Will exec [shell] group all criptnames script shell files"
        full_main
    fi

    ## exec script shell group
    if [[ $nflag -eq 1 ]]; then
        for scriptname in $scriptnames
        do
            info $LINENO "Will exec [$scriptname] group script shell group"
            if [[ -n scriptversions ]]; then
                main $scriptname  "$subscriptnames" "$scriptversions"
            else
            main $scriptname  "$subscriptnames"
        fi
        done
    fi

    ## set exec script file name
    if [[ $nflag -eq 0  && $fflag -eq 0  && $Fflag -eq 0 ]]; then
        warn $LINENO "You must give script name 'eg : getinfo' but 'getinfo' in pd.conf file"
        usage
    fi
fi
