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
export CREATE_RG=false
export RESOURCE_GROUP=rg-ae-prod-myapp-01

######################################
# Vnet and Subnet for the Deployment #
######################################
export CREATE_VNET_SNET=false
export VNET_NAME=vnet-ae-prod-myapp-01
export ADDRESS_PRIFIX="10.8.0.0/16"

export SNET_WEB_NAME=snet-ae-prod-myapp-web-01
export SNET_WEB_PRIFIX="10.8.4.0/24"
export SNET_APP_NAME=snet-ae-prod-myapp-app-01
export SNET_APP_PRIFIX="10.8.0.0/22"
export SNET_DB_NAME=snet-ae-prod-myapp-db-01
export SNET_DB_PRIFIX="10.8.5.0/24"
export SNET_BASTION_NAME=AzureBastionSubnet
export SNET_BASTION_PRIFIX="10.8.6.0/28"
export SNET_MGMT_NAME=snet-ae-prod-myapp-mgmt-02
export SNET_MGMT_PRIFIX="10.8.7.0/25"

export NSG_WEB_NAME=nsg-ae-prod-myapp-web-01
export NSG_APP_NAME=nsg-ae-prod-myapp-app-01
export NSG_DB_NAME=nsg-ae-prod-myapp-db-01
export NSG_BASTION_NAME=nsg-ae-prod-myapp-mgmt-01
export NSG_MGMT_NAME=nsg-ae-prod-myapp-mgmt-02

###################################
# Key Vault with Private Endpoint #
###################################
export CREATE_KV_SN=false
export KV_NAME=kv-ae-prod-myapp-01

export KV_PEP_NAME=pep-ae-prod-myapp-kv-01
export KV_PEP_CONN_NAME=pep-conn-ae-prod-myapp-kv-01
export KV_DNS_LINK_NAME=dns-link-ae-prod-myapp-kv-01
export KV_DNS_LINK=kv-ae-prod-myapp-01.vaultcore.azure.net
export KV_DNS_RECORD_SET=@

#########################################
# Redis for Cache with Private Endpoint #
#########################################
export CREATE_REDIS=false
export REDIS_DNS_NAME=redisaeprodmyapp01

#Use C1 Standard for Production
export REDIS_SKU=Standard
export REDIS_VM_SIZE=c1

export REDIS_PEP_NAME=pep-ae-prod-myapp-redis-01
export REDIS_PEP_CONN_NAME=pep-conn-ae-prod-myapp-redis-01
export REDIS_DNS_LINK_NAME=dns-link-ae-prod-myapp-redis-01
export REDIS_DNS_LINK=redisaeprodmyapp01.redis.cache.windows.net
export REDIS_DNS_RECORD_SET=@

#######################
# Postgres PRODUCTION #
#######################
export CREATE_POSTGRES=false

export POSTGRES_NAME=psql-ae-prod-myapp-01
export ADMIN_USER=myappadmin
export POSTGRES_SKU_NAME=GP_Gen5_2
export GEO_REDUNDANT=Enabled

#export POSTGRES_VNET_RULE=false
#export POSTGRES_VNET_RULE_NAME=psql-rule-myapp-01

export POSTGRES_PEP_NAME=pep-ae-prod-myapp-psql-01
export POSTGRES_PEP_CONN_NAME=pep-conn-ae-prod-myapp-psql-01
export POSTGRES_DNS_LINK_NAME=dns-link-ae-prod-myapp-psql-01
export POSTGRES_DNS_LINK=psql-ae-prod-myapp-01.postgres.database.azure.com
export POSTGRES_DNS_RECORD_SET=@

###############################################
# Storage Account GRS - Selected Network      #
# TODO: [Review - Allow Blob public access]   #
###############################################
export CREATE_STORAGE_ACCOUNT=false
export STORAGE_ACCOUNT_NAME=staeprodmyapp01
export STORAGE_SKU=Standard_GRS

export CONTAINER_NAME=myapp01
export FILE_SHARE=myapp01

#############################################
# Storage Account GRS - Public Network      #
#############################################
export CREATE_PUBLIC_CONTAINER=false

export PUBLIC_STORAGE_ACCOUNT_NAME=staeprodmyapp02
export PUBLIC_STORAGE_SKU=Standard_GRS

export PUBLIC_CONTAINER_NAME=\$web

######################
# Container Registry #
######################
export CREATE_ACR=false
export ACR_NAME=craeprodmyapp01

##################################
# Azure Kubernetes Service (AKS) #
##################################
export CREATE_AKS=false
export AKS_NAME=aks-ae-prod-myapp-01
export ADMIN_GROUP_NAME='AKS Production Admins'

#Leave it false always
export AKS_ADMIN_ACCESS=false

export ADD_SPOT_NODEPOOL=false
export ASSIGN_NW_CONTRIBUTOR_ROLE=false
export AAD_POD_IDENTITY=false

export LB_PRIVATEIP="10.8.3.250"
export INSTALL_INGRESS_CONTROLLER=false
export CLEANUP_DEFAULT_NS=false

export SETUP_AD_GROUPS=false
export CREATE_AD_GROUPS=false
export DEVOPS_GROUP_NAME="AKS DevOps Production Users"
export DEV_GROUP_NAME="AKS Production Users"

#######################
# Application Gateway #
#######################
export CREATE_PUBLIC_IP=false
export CREATE_AG=false

export AG_PUBLICIP_NAME=pip-ae-prod-myapp-ag-01
export AG_PUBLICIP_DNS=app-ae-prod
export AG_NAME=ag-ae-prod-myapp-01
export AG_SKU=Standard_v2
export AG_PRIVATE_IP="10.8.4.120"

#######################
# Install Prometheus  #
#######################
export INSTALL_PROMETHEUS=false
export VERIFY_DEFAULT_NGINX=false

###########
# Bastion #
###########
export CREATE_BASTION_PUBLIC_IP=false
export CREATE_BASTION=false

export BASTION_PUBLICIP_NAME=pip-ae-prod-myapp-bastion-01
export BASTION_PUBLICIP_DNS=app-ae-prod-bastion
export BASTION_NAME=bastion-ae-prod-myapp-01

#######################
# Lock Resource Group #
#######################
export LOCK_RG=false
export LOCK_NAME=lck-rg-ae-prod-myapp-01

#######################
# Destroy Parameters  #
#######################
export DELETE_AD_GROUPS=false
export PURGE_KV=false