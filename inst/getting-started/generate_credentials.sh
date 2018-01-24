#!/bin/sh
# Parse arguments

COMMAND=$1

if [[COMMAND == "create"]]; then
    echo "not implemented"
    exit 0
fi

if [[COMMAND == "get" || COMMAND == ""]]; then
    resource_group=$2
    location=$3
    batch_account_name=$4
    storage_account_name=$5

    # Get keys and urls
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
    exit 0
fi

