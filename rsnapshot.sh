#!/bin/bash
#
# rsnapshot.sh
# bash rsnapshot.sh alpha|beta|gamma|delta
# .\rsnapshot.sh alpha|beta|gamma|delta
#
# $1: backup type (alpha, beta, gamma, delta)
#

##### Variables #####
# Parameters
type=$1

# Constant
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Working var
hostname=$(hostname --fqdn)
gotifyUrl=$(cat $SCRIPT_DIR/gotifyUrl)
token=$(cat $SCRIPT_DIR/token)
completeUrl="$gotifyUrl/message?token=$token"
title=""
message=""
priority=5
doBackup=true
dateNow=$(date '+%Y-%m-%dT%H:%M')

# Backup Type
backupType=("alpha" "beta" "gamma" "delta")
declare -A backupTypeHuman
backupTypeHuman["alpha"]="Hourly"
backupTypeHuman["beta"]="Daily"
backupTypeHuman["gamma"]="Weekly"
backupTypeHuman["delta"]="Monthly"

##### Execution #####
# Test parameter value
if [[ ! " ${backupType[*]} " =~ [[:space:]]${type}[[:space:]] ]]; then
    title="Rsnapshot invalid backup type for $hostname"
    message="$type is not a valid backup type (alpha, beta, gamma, delta)."
    doBackup=false
else
    typeHuman=${backupTypeHuman["$type"]}
    title="Rsnapshot $typeHuman backup for $hostname"
    #echo "$type ($typeHuman) is a valid backup type."
fi

# Execute backup
if $doBackup; then
    /usr/bin/rsnapshot $type
    exitCode=$?

    if [ $exitCode -eq 0 ]; then
        message="$typeHuman backup ran successfully!"
    fi

    if [ $exitCode -ne 0 ]; then
        lastLog=$(tail -20 /var/log/rsnapshot/rsnapshot.log | grep "\[$dateNow")
        message=$"$typeHuman backup didn't run successfully!
        ----------------------------------------
        $lastLog"
        priority=10
    fi
fi

# Notify
curl -s $completeUrl -F "title=$title" -F "message=$message" -F "priority=$priority" > /dev/null

exit $exitCode
