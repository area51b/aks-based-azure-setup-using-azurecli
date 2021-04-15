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

#####################################
# Azure Location for the Deployment #
#####################################
export AZURE_TENANT=example.com
export AZURE_SUBSCRIPTION=

#####################################
# Azure Location for the Deployment #
#####################################
export AZURE_LOCATION=australiaeast
export AZURE_LOCATION_SHORT=ae

#####################################
# Resource Group for the Deployment #
#####################################
export CREATE_RG=true
export RESOURCE_GROUP=rg-ae-stg-myapp-01

######################################
# Vnet and Subnet for the Deployment #
######################################
export CREATE_VNET_SNET=true
export VNET_NAME=vnet-ae-stg-myapp-01
export ADDRESS_PRIFIX="10.6.0.0/16"

export SNET_WEB_NAME=snet-ae-stg-myapp-web-01
export SNET_WEB_PRIFIX="10.6.4.0/24"
export SNET_APP_NAME=snet-ae-stg-myapp-app-01
export SNET_APP_PRIFIX="10.6.0.0/22"
export SNET_DB_NAME=snet-ae-stg-myapp-db-01
export SNET_DB_PRIFIX="10.6.5.0/24"
export SNET_BASTION_NAME=AzureBastionSubnet
export SNET_BASTION_PRIFIX="10.6.6.0/28"
export SNET_MGMT_NAME=snet-ae-stg-myapp-mgmt-02
export SNET_MGMT_PRIFIX="10.6.7.0/25"

export NSG_WEB_NAME=nsg-ae-stg-myapp-web-01
export NSG_APP_NAME=nsg-ae-stg-myapp-app-01
export NSG_DB_NAME=nsg-ae-stg-myapp-db-01
export NSG_BASTION_NAME=nsg-ae-stg-myapp-mgmt-01
export NSG_MGMT_NAME=nsg-ae-stg-myapp-mgmt-02

###################################
# Key Vault with Private Endpoint #
###################################
export CREATE_KV_SN=true
export KV_NAME=kv-ae-stg-myapp-01

export KV_PEP_NAME=pep-ae-stg-myapp-kv-01
export KV_PEP_CONN_NAME=pep-conn-ae-stg-myapp-kv-01
export KV_DNS_LINK_NAME=dns-link-ae-stg-myapp-kv-01
export KV_DNS_LINK=kv-ae-stg-myapp-01.vaultcore.azure.net
export KV_DNS_RECORD_SET=@

#########################################
# Redis for Cache with Private Endpoint #
#########################################
export CREATE_REDIS=true
export REDIS_DNS_NAME=redisaestgmyapp01

#Use C1 Standard for Production
export REDIS_SKU=Basic
export REDIS_VM_SIZE=c0

export REDIS_PEP_NAME=pep-ae-stg-myapp-redis-01
export REDIS_PEP_CONN_NAME=pep-conn-ae-stg-myapp-redis-01
export REDIS_DNS_LINK_NAME=dns-link-ae-stg-myapp-redis-01
export REDIS_DNS_LINK=redisaestgmyapp01.redis.cache.windows.net
export REDIS_DNS_RECORD_SET=@

############################
# Postgres Basic (STAGING) #
############################
#export CREATE_POSTGRES_BASIC=true
export CREATE_POSTGRES=true

export POSTGRES_NAME=psql-ae-stg-myapp-01
export ADMIN_USER=myappadmin
export POSTGRES_SKU_NAME=GP_Gen5_2
export GEO_REDUNDANT=Disabled

#export POSTGRES_VNET_RULE=true
#export POSTGRES_VNET_RULE_NAME=psql-rule-myapp-01

export POSTGRES_PEP_NAME=pep-ae-stg-myapp-psql-01
export POSTGRES_PEP_CONN_NAME=pep-conn-ae-stg-myapp-psql-01
export POSTGRES_DNS_LINK_NAME=dns-link-ae-stg-myapp-psql-01
export POSTGRES_DNS_LINK=psql-ae-stg-myapp-01.postgres.database.azure.com
export POSTGRES_DNS_RECORD_SET=@

####################################################
# Storage Account LRS - Selected Network (STAGING) #
# TODO: [Review - Allow Blob public access]        #
####################################################
export CREATE_STORAGE_ACCOUNT=true
export STORAGE_ACCOUNT_NAME=staestgmyapp01
export STORAGE_SKU=Standard_LRS

export CONTAINER_NAME=myapp01
export FILE_SHARE=myapp01

##################################################
# Storage Account LRS - Public Network (STAGING) #
##################################################
export CREATE_PUBLIC_CONTAINER=true

export PUBLIC_STORAGE_ACCOUNT_NAME=staestgmyapp02
export PUBLIC_STORAGE_SKU=Standard_LRS

export PUBLIC_CONTAINER_NAME=\$web

######################
# Container Registry #
######################
export CREATE_ACR=true
export ACR_NAME=craestgmyapp01

##################################
# Azure Kubernetes Service (AKS) #
##################################
export CREATE_AKS=true
export AKS_NAME=aks-ae-stg-myapp-01
export ADMIN_GROUP_NAME='AKS Staging Admins'

#Leave it false always
export AKS_ADMIN_ACCESS=false

export ADD_SPOT_NODEPOOL=true
export ASSIGN_NW_CONTRIBUTOR_ROLE=true
export AAD_POD_IDENTITY=true

export LB_PRIVATEIP="10.6.3.250"
export INSTALL_INGRESS_CONTROLLER=true
export CLEANUP_DEFAULT_NS=true

export SETUP_AD_GROUPS=true
export CREATE_AD_GROUPS=true
export DEVOPS_GROUP_NAME="AKS DevOps Staging Users"
export DEV_GROUP_NAME="AKS Staging Users"

#######################
# Application Gateway #
#######################
export CREATE_PUBLIC_IP=true
export CREATE_AG=true

export AG_PUBLICIP_NAME=pip-ae-stg-myapp-ag-01
export AG_PUBLICIP_DNS=app-ae-stg
export AG_NAME=ag-ae-stg-myapp-01
export AG_SKU=Standard_v2
export AG_PRIVATE_IP="10.6.4.120"

#######################
# Install Prometheus  #
#######################
export INSTALL_PROMETHEUS=true
export VERIFY_DEFAULT_NGINX=true

###########
# Bastion #
###########
export CREATE_BASTION_PUBLIC_IP=true
export CREATE_BASTION=true

export BASTION_PUBLICIP_NAME=pip-ae-stg-myapp-bastion-01
export BASTION_PUBLICIP_DNS=app-ae-stg-bastion
export BASTION_NAME=bastion-ae-stg-myapp-01

#######################
# Lock Resource Group #
#######################
export LOCK_RG=true
export LOCK_NAME=lck-rg-ae-stg-myapp-01

#######################
# Destroy Parameters  #
#######################
export DELETE_AD_GROUPS=true
export PURGE_KV=true