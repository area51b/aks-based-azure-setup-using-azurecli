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
echo '####################'
echo '# Deployment Intro #'
echo '####################'
echo 'Sample Introduction...TODO'

echo
echo '###################'
echo '# Set Environment #'
echo '###################'
echo 'Deployment Environment: '${env}

ENV_TAG=$(echo ${env} | tr '[:lower:]' '[:upper:]')
echo 'Deployment Environment Tag: '${ENV_TAG}

echo -n "
Deployment Configurations:
    AZURE_TENANT: ${AZURE_TENANT}
    AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
    AZURE_LOCATION: ${AZURE_LOCATION}

    CREATE_RG: ${CREATE_RG}
    CREATE_VNET_SNET: ${CREATE_VNET_SNET}

    CREATE_KEY_VAULT: ${CREATE_KV_SN}
    CREATE_REDIS: ${CREATE_REDIS}
    CREATE_POSTGRES_BASIC: ${CREATE_POSTGRES_BASIC}
    CREATE_POSTGRES: ${CREATE_POSTGRES}
    CREATE_STORAGE_ACCOUNT: ${CREATE_STORAGE_ACCOUNT}
    CREATE_PUBLIC_CONTAINER: ${CREATE_PUBLIC_CONTAINER}

    AKS_ADMIN_ACCESS: ${AKS_ADMIN_ACCESS}

    CREATE_ACR: ${CREATE_ACR}
    CREATE_AKS: ${CREATE_AKS}
    ADD_SPOT_NODEPOOL: ${ADD_SPOT_NODEPOOL}
    AAD_POD_IDENTITY: ${AAD_POD_IDENTITY}
    INSTALL_INGRESS_CONTROLLER: ${INSTALL_INGRESS_CONTROLLER}
    ASSIGN_NW_CONTRIBUTOR_ROLE: ${ASSIGN_NW_CONTRIBUTOR_ROLE}
    SETUP_AD_GROUPS: ${SETUP_AD_GROUPS}

    CREATE_PUBLIC_IP: ${CREATE_PUBLIC_IP}
    CREATE_AG: ${CREATE_AG}
    INSTALL_PROMETHEUS: ${INSTALL_PROMETHEUS} 

    VERIFY_DEFAULT_NGINX: ${VERIFY_DEFAULT_NGINX}
    CREATE_BASTION_PUBLIC_IP: ${CREATE_BASTION_PUBLIC_IP}
    CREATE_BASTION: ${CREATE_BASTION}
"

read -t 60 -p "Do you want to create the environment? (y/n) " RESP
if [[ ! "$RESP" =~ ^(yes|y)$ ]]; then
    safeExit
fi

if [ "$CREATE_POSTGRES_BASIC" = true ] || [ "$CREATE_POSTGRES" = true ] ; 
then
    read -t 120 -p "Key in your postgres admin user password: " ADMIN_PWD
fi

echo
echo '##################################'
echo '# Login and set the subscription #'
echo '##################################'

[ ! -z "$AZURE_TENANT" ] && az login --tenant $AZURE_TENANT || az login

[ ! -z "$AZURE_SUBSCRIPTION" ] && az account set --subscription $AZURE_SUBSCRIPTION

az account list --output table

export SUBSCRIPTION_ID=$(az account show --query id --output tsv)

echo
read -t 60 -p "Do you want to proceed with SUBSCRIPTION_ID: ${SUBSCRIPTION_ID}? (y/n) " RESP
if [[ ! "$RESP" =~ ^(yes|y)$ ]]; then
    safeExit
fi

if [ "$CREATE_RG" = true ] ; 
then
    echo
    echo '#########################'
    echo '# Create Resource Group #'
    echo '#########################'

    az group create --name $RESOURCE_GROUP \
        --location $AZURE_LOCATION \
        --tags 'Name='$ACR_NAME 'Environment='$ENV_TAG
else
    echo 'Existing Resource Group: '$RESOURCE_GROUP
fi

if [ "$CREATE_VNET_SNET" = true ] ; 
then
    echo
    echo '######################'
    echo '# Create Vnet Subnet #'
    echo '######################'

    # Create a virtual network with aks subnet.
    az network vnet create \
        --name $VNET_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $AZURE_LOCATION \
        --address-prefix $ADDRESS_PRIFIX \
        --subnet-name $SNET_APP_NAME \
        --subnet-prefix $SNET_APP_PRIFIX \
        --ddos-protection false \
        --tags 'Name='$VNET_NAME 'Environment='$ENV_TAG

    # Create a web subnet.
    az network vnet subnet create \
        --address-prefix $SNET_WEB_PRIFIX \
        --name $SNET_WEB_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME

    # Create a db subnet.
    az network vnet subnet create \
        --address-prefix $SNET_DB_PRIFIX \
        --name $SNET_DB_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME

    # Create a bastion subnet.
    az network vnet subnet create \
        --address-prefix $SNET_BASTION_PRIFIX \
        --name $SNET_BASTION_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME

    # Create a management subnet.
    az network vnet subnet create \
        --address-prefix $SNET_MGMT_PRIFIX \
        --name $SNET_MGMT_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME

    # Create a network security group for the web subnet.
    az network nsg create \
        --resource-group $RESOURCE_GROUP \
        --name $NSG_WEB_NAME \
        --location $AZURE_LOCATION

    # Create a network security group for the app subnet.
    az network nsg create \
        --resource-group $RESOURCE_GROUP \
        --name $NSG_APP_NAME \
        --location $AZURE_LOCATION

    # Create a network security group for the db subnet.
    az network nsg create \
        --resource-group $RESOURCE_GROUP \
        --name $NSG_DB_NAME \
        --location $AZURE_LOCATION

    # Create a network security group for the bastion subnet.
    az network nsg create \
        --resource-group $RESOURCE_GROUP \
        --name $NSG_BASTION_NAME \
        --location $AZURE_LOCATION

    # Create a network security group for the management subnet.
    az network nsg create \
        --resource-group $RESOURCE_GROUP \
        --name $NSG_MGMT_NAME \
        --location $AZURE_LOCATION

    # Create an NSG rule to allow HTTP traffic in from the Internet to the web subnet.
    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_WEB_NAME \
        --name Allow-HTTP-All \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 100 \
        --source-address-prefix Internet \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 80

    # Create an NSG rule to allow HTTPS traffic in from the Internet to the web subnet.
    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_WEB_NAME \
        --name Allow-HTTPS-All \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 101 \
        --source-address-prefix Internet \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 443

    # Create an NSG rule to allow AG specific traffic from the Internet to the web subnet.
    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_WEB_NAME \
        --name Allow-AG-Ports \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 102 \
        --source-address-prefix Internet \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 65200-65535

    # Create an NSG rule to allow HTTP traffic from the web subnet to the app subnet.
    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_APP_NAME \
        --name Allow-HTTP-All \
        --access Allow --protocol Tcp \
        --direction Inbound \
        --priority 100 \
        --source-address-prefix $SNET_WEB_PRIFIX \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 80

    # Create an NSG rule to allow HTTPS traffic from the web subnet to the app subnet.
    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_APP_NAME \
        --name Allow-HTTPS-All \
        --access Allow --protocol Tcp \
        --direction Inbound \
        --priority 101 \
        --source-address-prefix $SNET_WEB_PRIFIX \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 443

    # Create an NSG rule to allow Postgres traffic from the app subnet to the db subnet.
    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_DB_NAME \
        --name Allow-Postgres-From-App \
        --access Allow --protocol Tcp \
        --direction Inbound \
        --priority 100 \
        --source-address-prefix $SNET_APP_PRIFIX \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 5432

    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_DB_NAME \
        --name Allow-Postgres-From-Mgmt \
        --access Allow --protocol Tcp \
        --direction Inbound \
        --priority 101 \
        --source-address-prefix $SNET_MGMT_PRIFIX \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 5432

    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_DB_NAME \
        --name Allow-Postgres-From-Bastion \
        --access Allow --protocol Tcp \
        --direction Inbound \
        --priority 102 \
        --source-address-prefix $SNET_BASTION_PRIFIX \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 5432

    # Create an NSG rule for bastion subnet.
    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_BASTION_NAME \
        --name AllowHTTPSInbound \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 100 \
        --source-address-prefix Internet \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 443

    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_BASTION_NAME \
        --name AllowGatewayManagerInbound \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 101 \
        --source-address-prefix GatewayManager \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 443

    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_BASTION_NAME \
        --name AllowAzureLoadBalancerInbound \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 102 \
        --source-address-prefix AzureLoadBalancer \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 443

    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_BASTION_NAME \
        --name AllowBastionHostCommunication \
        --access Allow \
        --protocol "*" \
        --direction Inbound \
        --priority 103 \
        --source-address-prefix VirtualNetwork \
        --source-port-range "*" \
        --destination-address-prefix VirtualNetwork \
        --destination-port-ranges 8080 5701


    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_BASTION_NAME \
        --name AllowSSHRDPOutbound \
        --access Allow \
        --protocol "*" \
        --direction Outbound \
        --priority 100 \
        --source-address-prefix "*" \
        --source-port-range "*" \
        --destination-address-prefix VirtualNetwork \
        --destination-port-ranges 22 3389

    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_BASTION_NAME \
        --name AllowAzureCloudOutbound \
        --access Allow \
        --protocol Tcp \
        --direction Outbound \
        --priority 101 \
        --source-address-prefix "*" \
        --source-port-range "*" \
        --destination-address-prefix AzureCloud \
        --destination-port-range 443

    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_BASTION_NAME \
        --name AllowBastionCommunication \
        --access Allow \
        --protocol "*" \
        --direction Outbound \
        --priority 102 \
        --source-address-prefix VirtualNetwork \
        --source-port-range "*" \
        --destination-address-prefix VirtualNetwork \
        --destination-port-ranges 8080 5701

    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_BASTION_NAME \
        --name AllowGetSessionInformation \
        --access Allow \
        --protocol "*" \
        --direction Outbound \
        --priority 103 \
        --source-address-prefix "*" \
        --source-port-range "*" \
        --destination-address-prefix Internet \
        --destination-port-range 80

    # Create an NSG rule to allow SSH traffic in from the Internet to the mgmt subnet.
    az network nsg rule create \
        --resource-group $RESOURCE_GROUP \
        --nsg-name $NSG_MGMT_NAME \
        --name Allow-SSH \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 100 \
        --source-address-prefix Internet \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 22

    # Associate the web NSG to the web subnet.
    az network vnet subnet update \
        --vnet-name $VNET_NAME \
        --name $SNET_WEB_NAME \
        --resource-group $RESOURCE_GROUP \
        --network-security-group $NSG_WEB_NAME

    # Associate the app NSG to the app subnet.
    az network vnet subnet update \
        --vnet-name $VNET_NAME \
        --name $SNET_APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --network-security-group $NSG_APP_NAME

    # Associate the db NSG to the db subnet.
    az network vnet subnet update \
        --vnet-name $VNET_NAME \
        --name $SNET_DB_NAME \
        --resource-group $RESOURCE_GROUP \
        --network-security-group $NSG_DB_NAME

    # Associate the bastion NSG to the bastion subnet.
    az network vnet subnet update \
        --vnet-name $VNET_NAME \
        --name $SNET_BASTION_NAME \
        --resource-group $RESOURCE_GROUP \
        --network-security-group $NSG_BASTION_NAME

    # Associate the bastion NSG to the mgmt subnet.
    az network vnet subnet update \
        --vnet-name $VNET_NAME \
        --name $SNET_MGMT_NAME \
        --resource-group $RESOURCE_GROUP \
        --network-security-group $NSG_MGMT_NAME
else
    echo 'Existing Virtual Network: '$VNET_NAME
fi

if [ "$CREATE_KV_SN" = true ] ; 
then
    echo
    echo '##########################################'
    echo '# Create Key Vault with Selected Network #'
    echo '##########################################'

    az network vnet subnet update \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME \
        --name $SNET_APP_NAME \
        --service-endpoints "Microsoft.KeyVault"

    az keyvault create \
        --location $AZURE_LOCATION \
        --name $KV_NAME \
        --resource-group $RESOURCE_GROUP \
        --network-acls-vnets /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$SNET_APP_NAME \
        --tags 'Name='$KV_NAME 'Environment='$ENV_TAG

    az keyvault update --resource-group $RESOURCE_GROUP --name $KV_NAME --default-action Deny

    az network vnet subnet update \
        --name $SNET_APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME \
        --disable-private-endpoint-network-policies true

    az network private-endpoint create \
        --name $KV_PEP_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME  \
        --subnet $SNET_APP_NAME \
        --private-connection-resource-id $(az resource show -g $RESOURCE_GROUP -n $KV_NAME --resource-type "Microsoft.KeyVault/vaults" --query "id" -o tsv) \
        --group-id vault \
        --connection-name $KV_PEP_CONN_NAME \
        --tags 'Name='$KV_PEP_NAME 'Environment='$ENV_TAG

    az network private-dns zone create --resource-group $RESOURCE_GROUP \
        --name  "$KV_DNS_LINK"

    az network private-dns link vnet create --resource-group $RESOURCE_GROUP \
        --zone-name  "$KV_DNS_LINK"\
        --name $KV_DNS_LINK_NAME \
        --virtual-network $VNET_NAME \
        --registration-enabled false

    #Query for the network interface ID  
    export KV_NETWORK_INTERFACE_ID=$(az network private-endpoint show --name $KV_PEP_NAME --resource-group $RESOURCE_GROUP --query 'networkInterfaces[0].id' -o tsv)
    
    az resource show --ids $KV_NETWORK_INTERFACE_ID --api-version 2019-04-01 -o json
    # Copy the content for privateIPAddress and FQDN matching the Key Vault
    export KV_PEP_PRIVATE_IP=$(az resource show --ids $KV_NETWORK_INTERFACE_ID --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
    echo 'KV Private IP: '$KV_PEP_PRIVATE_IP

    #Create DNS records 
    az network private-dns record-set a create --name $KV_DNS_RECORD_SET --zone-name $KV_DNS_LINK --resource-group $RESOURCE_GROUP
    az network private-dns record-set a add-record --record-set-name $KV_DNS_RECORD_SET --zone-name $KV_DNS_LINK --resource-group $RESOURCE_GROUP -a $KV_PEP_PRIVATE_IP

else
    echo 'Existing Key Vault: '$KV_NAME
fi

if [ "$CREATE_REDIS" = true ] ; 
then
    echo
    echo '################'
    echo '# Create Redis #'
    echo '################'

    az redis create \
        --location $AZURE_LOCATION \
        --name $REDIS_DNS_NAME \
        --resource-group $RESOURCE_GROUP \
        --sku $REDIS_SKU \
        --vm-size $REDIS_VM_SIZE \
        --minimum-tls-version 1.2 \
        --tags 'Name='$REDIS_DNS_NAME 'Environment='$ENV_TAG

    az network vnet subnet update \
        --name $SNET_DB_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME \
        --disable-private-endpoint-network-policies true

    az network private-endpoint create \
        --name $REDIS_PEP_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME  \
        --subnet $SNET_DB_NAME \
        --private-connection-resource-id $(az resource show -g $RESOURCE_GROUP -n $REDIS_DNS_NAME --resource-type "Microsoft.Cache/Redis" --query "id" -o tsv) \
        --group-id redisCache \
        --connection-name $REDIS_PEP_CONN_NAME \
        --tags 'Name='$REDIS_PEP_NAME 'Environment='$ENV_TAG

    az network private-dns zone create --resource-group $RESOURCE_GROUP \
        --name  "$REDIS_DNS_LINK"

    az network private-dns link vnet create --resource-group $RESOURCE_GROUP \
        --zone-name  "$REDIS_DNS_LINK"\
        --name $REDIS_DNS_LINK_NAME \
        --virtual-network $VNET_NAME \
        --registration-enabled false

    export REDIS_NETWORK_INTERFACE_ID=$(az network private-endpoint show --name $REDIS_PEP_NAME --resource-group $RESOURCE_GROUP --query 'networkInterfaces[0].id' -o tsv)
    
    az resource show --ids $REDIS_NETWORK_INTERFACE_ID --api-version 2019-04-01 -o json

    export REDIS_PEP_PRIVATE_IP=$(az resource show --ids $REDIS_NETWORK_INTERFACE_ID --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
    echo 'Redis Private IP: '$REDIS_PEP_PRIVATE_IP

    az network private-dns record-set a create --name $REDIS_DNS_RECORD_SET --zone-name $REDIS_DNS_LINK --resource-group $RESOURCE_GROUP
    az network private-dns record-set a add-record --record-set-name $REDIS_DNS_RECORD_SET --zone-name $REDIS_DNS_LINK --resource-group $RESOURCE_GROUP -a $REDIS_PEP_PRIVATE_IP
else
    echo 'Existing Redis: '$REDIS_DNS_NAME
    echo 'Existing Redis PEP: '$REDIS_PEP_NAME
fi

if [ "$CREATE_POSTGRES_BASIC" = true ] ; 
then
    echo
    echo '#########################'
    echo '# Create Postgres Basic #'
    echo '#########################'

    az postgres server create \
        --admin-password $ADMIN_PWD \
        --admin-user $ADMIN_USER \
        --location $AZURE_LOCATION \
        --minimal-tls-version TLS1_2 \
        --name $POSTGRES_NAME \
        --public-network-access Disabled \
        --geo-redundant-backup Disabled \
        --resource-group $RESOURCE_GROUP \
        --sku-name B_Gen5_2 \
        --ssl-enforcement Enabled \
        --storage-size 51200 \
        --tags 'Name='$POSTGRES_NAME 'Environment='$ENV_TAG \
        --version 11

elif [ "$CREATE_POSTGRES" = true ] ; 
then
    echo
    echo '###################'
    echo '# Create Postgres #'
    echo '###################'

    az postgres server create \
        --admin-password $ADMIN_PWD \
        --admin-user $ADMIN_USER \
        --location $AZURE_LOCATION \
        --minimal-tls-version TLS1_2 \
        --name $POSTGRES_NAME \
        --public-network-access Disabled \
        --geo-redundant-backup $GEO_REDUNDANT \
        --resource-group $RESOURCE_GROUP \
        --sku-name $POSTGRES_SKU_NAME \
        --ssl-enforcement Enabled \
        --storage-size 51200 \
        --tags 'Name='$POSTGRES_NAME 'Environment='$ENV_TAG \
        --version 11

    # if [ "$POSTGRES_VNET_RULE" = true ] ; 
    # then
    #     az network vnet subnet update \
    #         --resource-group $RESOURCE_GROUP \
    #         --vnet-name $VNET_NAME \
    #         --name $SNET_APP_NAME \
    #         --service-endpoints "Microsoft.SQL"

    #     az postgres server vnet-rule create \
    #         --name $POSTGRES_VNET_RULE_NAME \
    #         --resource-group $RESOURCE_GROUP \
    #         --server-name $POSTGRES_NAME \
    #         --vnet-name $VNET_NAME \
    #         --subnet $SNET_APP_NAME
    # fi

    az network vnet subnet update \
        --name $SNET_DB_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME \
        --disable-private-endpoint-network-policies true

    az network private-endpoint create \
        --name $POSTGRES_PEP_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME  \
        --subnet $SNET_DB_NAME \
        --private-connection-resource-id $(az resource show -g $RESOURCE_GROUP -n $POSTGRES_NAME --resource-type "Microsoft.DBforPostgreSQL/servers" --query "id" -o tsv) \
        --group-id postgresqlServer \
        --connection-name $POSTGRES_PEP_CONN_NAME

    az network private-dns zone create --resource-group $RESOURCE_GROUP \
        --name  "$POSTGRES_DNS_LINK"

    az network private-dns link vnet create --resource-group $RESOURCE_GROUP \
        --zone-name  "$POSTGRES_DNS_LINK"\
        --name $POSTGRES_DNS_LINK_NAME \
        --virtual-network $VNET_NAME \
        --registration-enabled false

    #Query for the network interface ID  
    export NETWORK_INTERFACE_ID=$(az network private-endpoint show --name $POSTGRES_PEP_NAME --resource-group $RESOURCE_GROUP --query 'networkInterfaces[0].id' -o tsv)
    
    az resource show --ids $NETWORK_INTERFACE_ID --api-version 2019-04-01 -o json
    # Copy the content for privateIPAddress and FQDN matching the Azure database for PostgreSQL name
    export PEP_PRIVATE_IP=$(az resource show --ids $NETWORK_INTERFACE_ID --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
    
    #Create DNS records 
    az network private-dns record-set a create --name $POSTGRES_DNS_RECORD_SET --zone-name $POSTGRES_DNS_LINK --resource-group $RESOURCE_GROUP
    az network private-dns record-set a add-record --record-set-name $POSTGRES_DNS_RECORD_SET --zone-name $POSTGRES_DNS_LINK --resource-group $RESOURCE_GROUP -a $PEP_PRIVATE_IP
else
    echo 'Existing Postgres : '$POSTGRES_NAME
fi

if [ "$CREATE_STORAGE_ACCOUNT" = true ] ; 
then

    echo
    echo '##########################'
    echo '# Create Storage Account #'
    echo '##########################'

    az storage account create --name $STORAGE_ACCOUNT_NAME \
        --resource-group $RESOURCE_GROUP \
        --access-tier Hot \
        --allow-blob-public-access true \
        --bypass AzureServices \
        --default-action Allow \
        --https-only true \
        --kind StorageV2 \
        --location ${AZURE_LOCATION} \
        --min-tls-version TLS1_2 \
        --sku $STORAGE_SKU \
        --tags 'Name='$STORAGE_ACCOUNT_NAME 'Environment='$ENV_TAG

    export STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT_NAME --query "[0].value" | tr -d '"')

    az storage container create \
        --account-name $STORAGE_ACCOUNT_NAME \
        --account-key $STORAGE_ACCOUNT_KEY \
        --name $CONTAINER_NAME --fail-on-exist

    az storage share create \
        --account-name $STORAGE_ACCOUNT_NAME \
        --account-key $STORAGE_ACCOUNT_KEY \
        --name $FILE_SHARE --fail-on-exist 

    az network vnet subnet update \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME \
        --name $SNET_APP_NAME \
        --service-endpoints "Microsoft.Storage"

    az storage account network-rule add -g $RESOURCE_GROUP \
        --account-name $STORAGE_ACCOUNT_NAME \
        --vnet-name $VNET_NAME \
        --subnet $SNET_APP_NAME

    az storage account update --default-action Deny \
        --name $STORAGE_ACCOUNT_NAME \
        --resource-group $RESOURCE_GROUP

else
    echo 'Existing Storage Account: '$STORAGE_ACCOUNT_NAME
fi

if [ "$CREATE_PUBLIC_CONTAINER" = true ] ; 
then

    echo
    echo '#################################'
    echo '# Create Public Storage Account #'
    echo '#################################'

    az storage account create --name $PUBLIC_STORAGE_ACCOUNT_NAME \
        --resource-group $RESOURCE_GROUP \
        --access-tier Hot \
        --allow-blob-public-access true \
        --bypass AzureServices \
        --default-action Allow \
        --https-only true \
        --kind StorageV2 \
        --location ${AZURE_LOCATION} \
        --min-tls-version TLS1_2 \
        --sku $PUBLIC_STORAGE_SKU \
        --tags 'Name='$PUBLIC_STORAGE_ACCOUNT_NAME 'Environment='$ENV_TAG

    export PUBLIC_STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $PUBLIC_STORAGE_ACCOUNT_NAME --query "[0].value" | tr -d '"')

    az storage container create \
        --account-name $PUBLIC_STORAGE_ACCOUNT_NAME \
        --account-key $PUBLIC_STORAGE_ACCOUNT_KEY \
        --name $PUBLIC_CONTAINER_NAME \
        --public-access blob \
        --fail-on-exist

else
    echo 'Existing Public Storage Account: '$PUBLIC_STORAGE_ACCOUNT_NAME
fi

if [ "$CREATE_ACR" = true ] ; 
then
    echo
    echo '#############################'
    echo '# Create Container Registry #'
    echo '#############################'

    az acr create --name $ACR_NAME \
                --resource-group $RESOURCE_GROUP \
                --sku Basic \
                --location $AZURE_LOCATION \
                --tags 'Name='$ACR_NAME 'Environment='$ENV_TAG
else
    echo 'Existing Container Registry: '$ACR_NAME
fi

if [ "$CREATE_AKS" = true ] ; 
then
    echo
    echo '##############'
    echo '# Create AKS #'
    echo '##############'

    export ADMIN_GROUP_OBJECTID="$(az ad group show --group $ADMIN_GROUP_NAME --query objectId -o tsv)"

    if [ -z "$ADMIN_GROUP_OBJECTID" ] ;
    then
        export ADMIN_GROUP_OBJECTID="$(az ad group create --display-name ${ADMIN_GROUP_NAME} --mail-nickname ${ADMIN_GROUP_NAME// /_} --query objectId -o tsv)"
    fi

    export TENANT_ID=$(az account show --query tenantId -o tsv)

    # Install the aks-preview extension
    az extension add --name aks-preview

    # Update the extension to make sure you have the latest version installed
    az extension update --name aks-preview

    # Create AKS
    az aks create --name $AKS_NAME \
        --resource-group $RESOURCE_GROUP \
        --enable-aad \
        --aad-admin-group-object-ids $ADMIN_GROUP_OBJECTID \
        --aad-tenant-id $TENANT_ID \
        --attach-acr $ACR_NAME \
        --dns-name-prefix ${AKS_NAME}-dns \
        --dns-service-ip "10.0.0.10" \
        --docker-bridge-address "172.17.0.1/16" \
        --enable-cluster-autoscaler \
        --enable-managed-identity \
        --generate-ssh-keys \
        --location ${AZURE_LOCATION} \
        --max-count 2 \
        --max-pods 50 \
        --min-count 1 \
        --node-count 1 \
        --network-plugin azure \
        --network-policy azure \
        --nodepool-name agentpool \
        --node-vm-size Standard_D4_v3 \
        --service-cidr "10.0.0.0/16" \
        --tags 'Name='$AKS_NAME 'Environment='$ENV_TAG \
        --vnet-subnet-id /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$SNET_APP_NAME \
        --zones 3

    az aks enable-addons -a monitoring -n $AKS_NAME -g $RESOURCE_GROUP

    export AKS_MC_RG=$(az group list --query "[?starts_with(name, 'MC_${RESOURCE_GROUP}_$AKS_NAME')].name | [0]" --output tsv)
    echo 'AKS MC Resource Group: '$AKS_MC_RG
else
    echo 'Existing AKS: '$AKS_NAME
    echo 'Existing ACR: '$ACR_NAME

    export AKS_MC_RG=$(az group list --query "[?starts_with(name, 'MC_${RESOURCE_GROUP}_$AKS_NAME')].name | [0]" --output tsv)
    echo 'AKS MC Resource Group: '$AKS_MC_RG
fi

#Spot Nodepool doesnt work with AAD POD Identity
if [ "$ADD_SPOT_NODEPOOL" = true ] ; 
then
    echo
    echo '#######################'
    echo '# Add Spot Node Pool  #'
    echo '#######################'

    az feature register --namespace "Microsoft.ContainerService" --name "spotpoolpreview"

    az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/spotpoolpreview')].{Name:name,State:properties.state}"

    az provider register --namespace Microsoft.ContainerService

    az aks nodepool add \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $AKS_NAME \
        --name spotnodepool \
        --priority Spot \
        --eviction-policy Delete \
        --spot-max-price -1 \
        --node-vm-size Standard_D4_v3 \
        --enable-cluster-autoscaler \
        --max-pods 50 \
        --min-count 1 \
        --max-count 2 \
        --node-count 1 \
        --zones 3
fi

if [ "$ASSIGN_NW_CONTRIBUTOR_ROLE" = true ] ; 
then
    echo
    echo '###############################################'
    echo '# Assign Network Contributor Role for AKS IDs #'
    echo '###############################################'
    export IDENTITY_NAME="${AKS_NAME}"
    echo 'Managed AKS Identity Name: '$IDENTITY_NAME

    export IDENTITY_CLIENT_ID="$(az ad sp list --all --query "[?displayName=='${IDENTITY_NAME}'].appId | [0]" --output tsv)"
    echo 'Managed AKS Identity Id1: '$IDENTITY_CLIENT_ID

    #Assign Network Contributor Role for 
    az role assignment create --role "Network Contributor" --assignee $IDENTITY_CLIENT_ID --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME

    export IDENTITY_NAME_AP="${AKS_NAME}-agentpool"
    echo 'Managed AKS Identity Name 2: '$IDENTITY_NAME_AP

    export IDENTITY_CLIENT_AP_ID="$(az identity show -g $AKS_MC_RG -n $IDENTITY_NAME_AP --subscription $SUBSCRIPTION_ID --query clientId -otsv)"
    echo 'Managed AKS Identity Id2: '$IDENTITY_CLIENT_AP_ID

    az role assignment create --role "Network Contributor" --assignee $IDENTITY_CLIENT_AP_ID --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME
fi

if [ "$AKS_ADMIN_ACCESS" = true ] ; 
then
    #To get AKS access as admin
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --admin --overwrite-existing
else
    #To get AKS access
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing
fi

#Login to ACR
az acr login --name $ACR_NAME

if [ "$AAD_POD_IDENTITY" = true ] ; 
then
    echo
    echo '##################################################'
    echo '# Create AAD Pods and Assign Roles for Key Vault #'
    echo '##################################################'
    helm3 repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
    helm3 repo update

    helm3 install aad-pod-identity aad-pod-identity/aad-pod-identity --namespace kube-system

    #new user manager identity
    export AAD_IDENTITY_NAME="smid-${AKS_NAME}"
    az identity create -g $AKS_MC_RG -n $AAD_IDENTITY_NAME --subscription $SUBSCRIPTION_ID

    export AAD_IDENTITY_CLIENT_ID="$(az identity show -g $AKS_MC_RG -n $AAD_IDENTITY_NAME --subscription $SUBSCRIPTION_ID --query clientId -otsv)"
    export AAD_IDENTITY_RESOURCE_ID="$(az identity show -g $AKS_MC_RG -n $AAD_IDENTITY_NAME --subscription $SUBSCRIPTION_ID --query id -otsv)"

    export AAD_IDENTITY_ASSIGNMENT_ID="$(az role assignment create --role Reader --assignee $AAD_IDENTITY_CLIENT_ID --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$AKS_MC_RG --query id -otsv)"

    export AKS_CLIENT_ID="$(az aks show -g $RESOURCE_GROUP -n $AKS_NAME --query identityProfile.kubeletidentity.clientId -otsv)"

    az role assignment create --role "Managed Identity Operator" --assignee $AKS_CLIENT_ID --scope /subscriptions/$SUBSCRIPTION_ID/resourcegroups/$AKS_MC_RG
    az role assignment create --role "Virtual Machine Contributor" --assignee $AKS_CLIENT_ID --scope /subscriptions/$SUBSCRIPTION_ID/resourcegroups/$AKS_MC_RG

    az role assignment create --role Reader --assignee $AAD_IDENTITY_CLIENT_ID --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KV_NAME

    export IDENTITY_OBJECT_ID="$(az identity show -g $AKS_MC_RG -n $AAD_IDENTITY_NAME --subscription $SUBSCRIPTION_ID --query principalId -otsv)"

    az keyvault set-policy --name $KV_NAME \
                --subscription $SUBSCRIPTION_ID \
                --resource-group $RESOURCE_GROUP \
                --object-id $IDENTITY_OBJECT_ID \
                --secret-permissions get list

    cat ./parameters/podidentity.yaml | sed "s/{{IDENTITY_NAME}}/$AAD_IDENTITY_NAME/g" \
            | sed "s/{{IDENTITY_CLIENT_ID}}/$AAD_IDENTITY_CLIENT_ID/g" \
            | sed "s/{{SUBSCRIPTION_ID}}/$SUBSCRIPTION_ID/g" \
            | sed "s/{{RESOURCE_GROUP}}/$AKS_MC_RG/g" | kubectl apply -f -

    cat ./parameters/podidentitybinding.yaml | sed "s/{{IDENTITY_NAME}}/$AAD_IDENTITY_NAME/g" | kubectl apply -f -

    # Verify from POD with aadpodidbinding (example: unify-pdf-generator)
    # curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s
fi

if [ "$INSTALL_INGRESS_CONTROLLER" = true ] ; 
then
    echo
    echo '###################################'
    echo '# Ingress Controller and Resource #'
    echo '###################################'

    helm3 repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm3 repo add stable https://charts.helm.sh/stable
    helm3 repo update

    #Custom Ingress Class
    kubectl create -f ./parameters/ingress-class.yaml

    cat ./parameters/internal-ingress.yaml | sed "s/{{LB_PRIVATEIP}}/$LB_PRIVATEIP/g" \
            | helm3 install nginx-ingress ingress-nginx/ingress-nginx \
                --namespace kube-system \
                -f - \
                --set rbac.create=true \
                --set controller.ingressClass=external-lb \
                --set controller.replicaCount=2 \
                --set controller.stats.enabled=true \
                --set controller.metrics.enabled=true \
                --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
                --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
                --set controller.service.externalTrafficPolicy="Local" \
                --wait --timeout 30m0s
    
    kubectl create namespace myapp --dry-run=client -o yaml | kubectl apply -f -

    #Sample NGINX deployment on default namespace
    kubectl create -f ./parameters/sample-deployment.yaml

    #Sample NGINX Service on default namespace
    kubectl expose deployment/nginx-deployment --name=nginx-service --namespace=myapp

    #Sample Ingress Resource to test the NGINX Deployment on default namespace
    kubectl create -f ./parameters/ingress_resource.yaml
else
    echo 'Existing Ingress Controller and Resource'
fi

if [ "$SETUP_AD_GROUPS" = true ] ; 
then

    if [ "$CREATE_AD_GROUPS" = true ] ; 
    then
        echo
        echo '####################'
        echo '# Create AD Groups #'
        echo '####################'
        export AKS_ID="$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query id -o tsv)"

        export APPDEVOPS_ID="$(az ad group create --display-name ${DEVOPS_GROUP_NAME} --mail-nickname ${DEVOPS_GROUP_NAME// /_} --query objectId -o tsv)"

        az role assignment create \
            --assignee $APPDEVOPS_ID \
            --role "Azure Kubernetes Service Cluster User Role" \
            --scope $AKS_ID

        export APPDEV_ID="$(az ad group create --display-name ${DEV_GROUP_NAME} --mail-nickname ${DEV_GROUP_NAME// /_} --query objectId -o tsv)"

        az role assignment create \
            --assignee $APPDEV_ID \
            --role "Azure Kubernetes Service Cluster User Role" \
            --scope $AKS_ID
    fi

    echo
    echo '########################'
    echo '# Create Cluster Roles #'
    echo '########################'

    #Get Group ID and replace it in the Role Bindings
    export APPDEVOPS_OBJECTID="$(az ad group show --group $DEVOPS_GROUP_NAME --query objectId -o tsv)"
    export APPDEV_OBJECTID="$(az ad group show --group $DEV_GROUP_NAME --query objectId -o tsv)"

    kubectl create namespace myapp --dry-run=client -o yaml | kubectl apply -f -

    #Create ClusterRole for Cluster wide permission
    kubectl apply -f ./parameters/aks-cluster-role.yaml

    #Create Role for specific namespace permission
    kubectl apply -f ./parameters/aks-role.yaml

    #Create Cluster Role Binding
    cat ./parameters/aks-cluster-role-binding.yaml | sed "s/{{APPDEVOPS_OBJECTID}}/$APPDEVOPS_OBJECTID/g" | kubectl apply -f -
    
    #Create Role Binding
    cat ./parameters/aks-role-binding.yaml | sed "s/{{APPDEV_OBJECTID}}/$APPDEV_OBJECTID/g" | kubectl apply -f -
fi

if [ "$CREATE_PUBLIC_IP" = true ] ; 
then
    echo
    echo '####################'
    echo '# Create Public IP #'
    echo '####################'

    az network public-ip create \
        --resource-group $RESOURCE_GROUP \
        --name $AG_PUBLICIP_NAME \
        --dns-name $AG_PUBLICIP_DNS \
        --allocation-method Static \
        --sku Standard \
        --tags 'Name='$AG_PUBLICIP_NAME 'Environment='$ENV_TAG

else
    echo 'Existing AG Public IP'
fi

if [ "$CREATE_AG" = true ] ; 
then
    echo
    echo '###############################'
    echo '# Create Application Gateway #'
    echo '###############################'

    #Nwe AG with AKS LB as backend pool
    az network application-gateway create \
        --name $AG_NAME \
        --location $AZURE_LOCATION \
        --resource-group $RESOURCE_GROUP \
        --capacity 2 \
        --sku $AG_SKU \
        --http-settings-cookie-based-affinity Enabled \
        --public-ip-address $AG_PUBLICIP_NAME \
        --vnet-name $VNET_NAME \
        --subnet $SNET_WEB_NAME \
        --servers "$LB_PRIVATEIP" \
        --private-ip-address "$AG_PRIVATE_IP" \
        --tags 'Name='$AG_NAME 'Environment='$ENV_TAG

else
    echo 'Existing Application Gateway'
fi

if [ "$INSTALL_PROMETHEUS" = true ] ; 
then
    echo
    echo '######################'
    echo '# Install Prometheus #'
    echo '######################'

    kubectl create ns kube-monitor

    helm3 install prometheus stable/prometheus-operator --version=8.13.8 --namespace kube-monitor

fi

if [ "$VERIFY_DEFAULT_NGINX" = true ] ; 
then
    echo
    echo '########################'
    echo '# Verify Default NGINX #'
    echo '########################'

    wget -O- http://${AG_PUBLICIP_DNS}.${AZURE_LOCATION}.cloudapp.azure.com

    if [ "$CLEANUP_DEFAULT_NS" = true ] ; 
    then
        #Delete sample NGINX deployment on default namespace
        kubectl delete -f ./parameters/sample-deployment.yaml

        #Delete sample NGINX Service on default namespace
        kubectl delete svc nginx-service --namespace=myapp
    fi
fi

if [ "$CREATE_BASTION_PUBLIC_IP" = true ] ; 
then
    echo
    echo '############################'
    echo '# Create Bastion Public IP #'
    echo '############################'

    az network public-ip create \
        --resource-group $RESOURCE_GROUP \
        --name $BASTION_PUBLICIP_NAME \
        --dns-name $BASTION_PUBLICIP_DNS \
        --allocation-method Static \
        --sku Standard \
        --zone 1 2 3 \
        --tags 'Name='$BASTION_PUBLICIP_NAME 'Environment='$ENV_TAG

else
    echo 'Existing Bastion Public IP'
fi

if [ "$CREATE_BASTION" = true ] ; 
then
    echo
    echo '##################'
    echo '# Create Bastion #'
    echo '##################'

    az network bastion create \
        --name $BASTION_NAME \
        --public-ip-address $BASTION_PUBLICIP_NAME \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME \
        --location $AZURE_LOCATION

else
    echo 'Existing Bastion'
fi

if [ "$LOCK_RG" = true ] ; 
then
    echo
    echo '#######################'
    echo '# Lock Resource Group #'
    echo '#######################'

    az lock create --name $LOCK_NAME --lock-type CanNotDelete --resource-group $RESOURCE_GROUP
    #az lock delete --name $LOCK_NAME --resource-group $RESOURCE_GROUP
fi

echo
echo '#############'
echo '# AZ Logout #'
echo '#############'
az logout
