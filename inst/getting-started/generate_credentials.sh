#!/bin/sh
# Parse arguments

programname=$0
print_usage() {
    echo "$programname allows you to easily create and manage the resources required to use doAzureParallel."
    echo "There are several actions you can take:"
    echo "   create: creates a new set of resources required for doAzureParallel"
    echo "   options:"
    echo "            region:           (required)"
    echo "            resource_group:   (optional: default= 'doazureparallel)"
    echo "            batch_account:    (optional: default= 'doazureparallel_ba)"
    echo "            storage_account:  (optional: default= 'doazureparallel_sa)"
    echo ""
    echo "   example usage:"
    echo "   $programname create westus"
    echo "   $programname create westus my_resource_group_name my_batch_account_name my_storage_account_name"
}

# Parameters
# $1 region
# $2 resource group
# $3 batch account
# $4 storage account
create_accounts() {
    location=$1
    resource_group=$2
    batch_account=$3
    storage_account=$4
    # Create resource group    
    az group create -n $resource_group -l $location

    # Create storage account
    az storage account create \
	--name $storage_account \
	--sku Standard_LRS \
	--location $location \
	--resource-group $resource_group

    # Create batch account
    az batch account create \
	--name $batch_account \
	--location $location \
	--resource-group $resource_group \
	--storage-account $storage_account
}

# Parameters
# $1 resource group
# $2 batch account
# $3 storage account
get_credentials() {
    # Get keys and urls
    resource_group=$1
    batch_account_name=$2
    storage_account_name=$3

    echo "debug: getting keys for $resource_group, $batch_account_name, $storage_account_name"

    batch_account_key="$(az batch account keys list \
            --name $batch_account_name \
            --resource-group $resource_group \
            | jq '{key: .primary}' | jq .[])"
    batch_account_url="$(az batch account list \
            --resource-group $resource_group \
            | jq .[0].accountEndpoint)"
    storage_account_key="$(az storage account keys list \
            --account-name $storage_account_name \
            --resource-group $resource_group \
            | jq '.[0].value')"
    storage_account_url="$(az storage account show \
        --resource-group abc \
        --name prodtest5 \
        | jq .primaryEndpoints.blob)"

    export JSON='{\n
        "batchAccount": { \n
            "name": "'"$batch_account_name"'", \n
            "key": '$batch_account_key', \n
            "url": '$batch_account_url' \n
        }, \n
        "storageAccount": { \n
            "name": "'"$storage_account_name"'", \n
            "key": '$storage_account_key', \n
            "url": '$storage_account_url' \n
        }\n}'
    echo $JSON
}

if [ "$#" -eq 0 ]; then
    print_usage
    exit 1
fi

COMMAND=$1

if [ "$COMMAND" = "create" ]; then
    echo "not implemented"

    location=$2

    if [ "$location" = "" ]; then
        echo "missing required input 'region'"
        print_usage
        exit 1
    fi

    resource_group=$2
    batch_account_name=$3
    storage_account_name=$4

    # Set defaults
    if [ "$resource_group" = "" ]; then
        resource_group="doazureparallel"
    fi

    if [ "$batch_account_name" = "" ]; then
        batch_account_name="doazureparallel_ba"
    fi

    if [ "$storage_account_name" = "" ]; then
        storage_account_name="doazureparallel_sa"
    fi

    create_accounts $location $resource_group $batch_account $storage_account

fi

if [ "$COMMAND" = "get"  ]; then
    resource_group=$2
    batch_account_name=$3
    storage_account_name=$4

    # Set defaults
    if [ "$resource_group" = "" ]; then
        resource_group="doazureparallel"
    fi

    if [ "$batch_account_name" = "" ]; then
        batch_account_name="doazureparallel_ba"
    fi

    if [ "$storage_account_name" = "" ]; then
        storage_account_name="doazureparallel_sa"
    fi

    get_credentials $resource_group $batch_account_name $storage_account_name
    
fi

exit 0