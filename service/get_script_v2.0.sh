#!/usr/bin/env bash
# author leidong

TOP_DIR=${TOP_DIR:-$(cd $(dirname "$0")/.. && pwd)}

CMD_SH=$(which ksh 2>/dev/null)
[[ $? -ne 0 ]] && CMD_SH=$(which sh)
[[ ! -d $SCRIPT_LOG ]] && mkdir -p $SCRIPT_LOG

if [[ -d $UNIT_DIR ]]; then
    
    source $UNIT_DIR/functions
else
    source $TOP_DIR/unit/functions
fi

function getinfo {
    local comnames=$@
    local args=$@
}

function get_args {
    local nrname=$1
    local funcname=$2
    local outargs=$3

    [[ -f $ARGS_FILE ]] || echo "Not Found config $ARGS_FILE"
    [[ -n $nrname ]] || echo "var nrname is not set"
    get_args_conf $nrname $ARGS_FILE $function outargs
    [[ -n $outargs ]] ||echo "Not Found script $nrname args" && echo $outargs
}

function get_funcs {
    local funcnames=$1
    local subcom=$2
    [[ -n $funcnames ]] ||  echo "ERROR: Input function name $funcnames"
}

function get_script_file {
    local scriptname=$(basename $1)
    local scriptdir=$(dirname $1)
    local outscript=$2

    [[ -d $CLIENT_DIR ]] || die $LINENO "Not Found config $CLIENT_DIR"
    ret=$(find $CLIENT_DIR/$scriptdir -name "$scriptname" -type f)
    [[ -n $ret ]] && eval $outscript=$ret || die $LINENO "Not Found script file $scriptname"
}

function  exec_funcs {
    local nrname=$1
    local subcoms=$2

    if [[ -n "$subcoms" ]]; then
        for subcom in $subcoms
        do
            get_script_conf $nrname $SCRIPT_FILE $subcom outfunc 

            get_args_conf $nrname $ARGS_FILE $subcom outargs

            funcname=$(echo $outfunc | cut -d"=" -f2)

            get_script_file $funcname exec_script
            args=$(echo $outargs | sed 's/[#|@]/ /g')

            $CMD_SH $exec_script $args &>>/$LOG_DIR/${funcname}.log
            [[ $? -eq 0 ]] && passed "${funcname} script is passed" || failed "${funcname} script is failed"

        done
    else
        outfuncs=$(get_script_conf $nrname $SCRIPT_FILE all)
        for outfunc in $outfuncs
        do
            subcom=$(echo $outfunc | cut -d"=" -f1) 
            funcname=$(echo $outfunc | cut -d"=" -f2) 
            get_args_conf $nrname $ARGS_FILE $subcom outargs

            get_script_file $funcname exec_script
            args=$(echo $outargs | sed 's/[#|@]/ /g')

            $CMD_SH $exec_script $args &>>/$LOG_DIR/${funcname}.log
            [[ $? -eq 0 ]] && passed "${funcname} script is passed" || failed "${funcname} script is failed"
        done
    fi
}

##-----------------main function -----------------------##
function main {
    local nrname=$1
    local subcoms=$2
    exec_funcs $nrname "$subcoms"
}
