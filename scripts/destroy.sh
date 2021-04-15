#!/bin/bash

# ---------------------------------------------------------------------------
# This is run script... TODO

# Usage: run.sh [OPTIONS]
# Options
#  -c, --command     Command for script [deploy | destroy]
#  -e, --env         Environment for the script [staging | production]
#  -l, --log         Print log to file
#  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
#  -d, --debug       Runs script in BASH debug mode (set -x)
#  -h, --help        Display this help and exit
#      --version     Output version information and exit
# Example
#  ./run.sh -c deploy -e staging -l
#  ./run.sh -c destroy -e staging -l
# ---------------------------------------------------------------------------

echo
echo '#################'
echo '# Destroy Intro #'
echo '#################'
echo 'Sample Introduction...TODO'

echo
echo '###################'
echo '# Set Environment #'
echo '###################'
echo 'Deployment Environment: '${env}

read -p "Do you want to delete RG "$RESOURCE_GROUP" and all related resources? (y/n) " RESP

echo
echo '##################################'
echo '# Login and set the subscription #'
echo '##################################'

[ ! -z "$AZURE_TENANT" ] && az login --tenant $AZURE_TENANT || az login

[ ! -z "$AZURE_SUBSCRIPTION" ] && az account set --subscription $AZURE_SUBSCRIPTION

az account list --output table

echo
echo '###############################################'
echo '# Delete Resource Group and Related Resources #'
echo '###############################################'
if [[ "$RESP" =~ ^(yes|y)$ ]]; then
    az group delete --name $RESOURCE_GROUP

    if [ "$PURGE_KV" = true ] ; 
    then
        echo
        echo '###################'
        echo '# Purge Key Valut #'
        echo '###################'
        az keyvault purge \
            --location $AZURE_LOCATION \
            --name $KV_NAME
    fi

    if [ "$DELETE_AD_GROUPS" = true ] ; 
    then
        echo
        echo '###########################'
        echo '# Delete DevOps AD Groups #'
        echo '###########################'

        az ad group delete --group $DEVOPS_GROUP_NAME

        az ad group delete --group $DEV_GROUP_NAME
    fi
else
    echo "Action Cancelled!!!"
fi
