'''
    doAzureParallel Getting Started script
'''
import sys
import threading
import time
import uuid
import json
from azure.common import credentials
from azure.graphrbac import GraphRbacManagementClient
from azure.graphrbac.models import ApplicationCreateParameters, PasswordCredential, ServicePrincipalCreateParameters
from azure.graphrbac.models.graph_error import GraphErrorException
from azure.mgmt.authorization import AuthorizationManagementClient
from azure.mgmt.batch import BatchManagementClient
from azure.mgmt.batch.models import AutoStorageBaseProperties, BatchAccountCreateParameters
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.network.models import AddressSpace, Subnet, VirtualNetwork
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.storage.models import Kind, Sku, SkuName, StorageAccountCreateParameters
from azure.mgmt.subscription import SubscriptionClient
from datetime import datetime, timezone
from msrestazure.azure_cloud import AZURE_PUBLIC_CLOUD
from msrestazure.azure_exceptions import CloudError


class AccountSetupError(Exception):
    pass


class DefaultSettings():
    authentication = "1"
    resource_group = 'doazureparallel'
    storage_account = 'doazureparallelstorage'
    batch_account = 'doazureparallelbatch'
    application_name = 'doazureparallelapplication'
    application_credential_name = 'doazureparallelapplicationcredential'
    service_principal = 'doazureparallelsp'
    region = 'westus'


def create_resource_group(credentials, subscription_id, **kwargs):
    """
        Create a resource group
        :param credentials: msrestazure.azure_active_directory.AdalAuthentication
        :param subscription_id: str
        :param **resource_group: str
        :param **region: str
    """
    resource_client = ResourceManagementClient(credentials, subscription_id)
    resource_client.resource_groups.list()
    for i in range(3):
        try:
            resource_group = resource_client.resource_groups.create_or_update(
                resource_group_name=kwargs.get("resource_group", DefaultSettings.resource_group),
                parameters={
                    'location': kwargs.get("region", DefaultSettings.region),
                }
            )
        except CloudError as e:
            if i == 2:
                raise AccountSetupError(
                    "Unable to create resource group in region {}".format(kwargs.get("region", DefaultSettings.region)))
            print(e.message)
            print("Please try again.")
            kwargs["resource_group"] = prompt_with_default("Azure Region", DefaultSettings.region)
    return resource_group.id


def create_storage_account(credentials, subscription_id, **kwargs):
    """
        Create a Storage account
        :param credentials: msrestazure.azure_active_directory.AdalAuthentication
        :param subscription_id: str
        :param **resource_group: str
        :param **storage_account: str
        :param **region: str
    """
    storage_management_client = StorageManagementClient(credentials, subscription_id)
    storage_account = storage_management_client.storage_accounts.create(
        resource_group_name=kwargs.get("resource_group", DefaultSettings.resource_group),
        account_name=kwargs.get("storage_account", DefaultSettings.storage_account),
        parameters=StorageAccountCreateParameters(
            sku=Sku(SkuName.standard_lrs),
            kind=Kind.storage,
            location=kwargs.get('region', DefaultSettings.region)
        )
    )
    return storage_account.result().id

def storage_account_get_keys(credentials, subscription_id, **kwargs):
    """
        get Storage account keys
        :param credentials: msrestazure.azure_active_directory.AdalAuthentication
        :param subscription_id: str
        :param **resource_group: str
        :param **storage_account: str
        :param **region: str
    """
    storage_management_client = StorageManagementClient(credentials, subscription_id)
    storage_account_keys = storage_management_client.storage_accounts.list_keys(
        resource_group_name=kwargs.get("resource_group", DefaultSettings.resource_group),
        account_name=kwargs.get("storage_account", DefaultSettings.storage_account)
    )
    return storage_account_keys.keys[0].value


def create_batch_account(credentials, subscription_id, **kwargs):
    """
        Create a Batch account
        :param credentials: msrestazure.azure_active_directory.AdalAuthentication
        :param subscription_id: str
        :param **resource_group: str
        :param **batch_account: str
        :param **region: str
        :param **storage_account_id: str
    """
    batch_management_client = BatchManagementClient(credentials, subscription_id)
    batch_account = batch_management_client.batch_account.create(
        resource_group_name=kwargs.get("resource_group", DefaultSettings.resource_group),
        account_name=kwargs.get("batch_account", DefaultSettings.batch_account),
        parameters=BatchAccountCreateParameters(
            location=kwargs.get('region', DefaultSettings.region),
            auto_storage=AutoStorageBaseProperties(
                storage_account_id=kwargs.get('storage_account_id', DefaultSettings.region)
            )
        )
    )
    return batch_account.result().id


def batch_account_get_keys(credentials, subscription_id, **kwargs):
    """
        get Batch account keys
        :param credentials: msrestazure.azure_active_directory.AdalAuthentication
        :param subscription_id: str
        :param **resource_group: str
        :param **batch_account: str
    """
    batch_management_client = BatchManagementClient(credentials, subscription_id)
    batch_account_keys = batch_management_client.batch_account.get_keys(
        resource_group_name=kwargs.get("resource_group", DefaultSettings.resource_group),
        account_name=kwargs.get("batch_account", DefaultSettings.batch_account)
    )
    return batch_account_keys.primary

def create_vnet(credentials, subscription_id, **kwargs):
    """
        Create a Batch account
        :param credentials: msrestazure.azure_active_directory.AdalAuthentication
        :param subscription_id: str
        :param **resource_group: str
        :param **virtual_network_name: str
        :param **subnet_name: str
        :param **region: str
    """
    network_client = NetworkManagementClient(credentials, subscription_id)
    resource_group_name = kwargs.get("resource_group", DefaultSettings.resource_group)
    virtual_network_name = kwargs.get("virtual_network_name", DefaultSettings.virtual_network_name)
    subnet_name = kwargs.get("subnet_name", DefaultSettings.subnet_name)
    # get vnet, and subnet if they exist
    virtual_network = subnet = None
    try:
        virtual_network = network_client.virtual_networks.get(
            resource_group_name=resource_group_name,
            virtual_network_name=virtual_network_name,
        )
    except CloudError as e:
        pass

    if virtual_network:
        confirmation_prompt = "A virtual network with the same name ({}) was found. \n"\
                             "Please note that the existing address space and subnets may be changed or destroyed. \n"\
                             "Do you want to use this virtual network? (y/n): ".format(virtual_network_name)
        deny_error = AccountSetupError("Virtual network already exists, not recreating.")
        unrecognized_input_error = AccountSetupError("Input not recognized.")
        prompt_for_confirmation(confirmation_prompt, deny_error, unrecognized_input_error)

    virtual_network = network_client.virtual_networks.create_or_update(
        resource_group_name=resource_group_name,
        virtual_network_name=kwargs.get("virtual_network_name", DefaultSettings.virtual_network_name),
        parameters=VirtualNetwork(
            location=kwargs.get("region", DefaultSettings.region),
            address_space=AddressSpace(["10.0.0.0/24"])
        )
    )
    virtual_network = virtual_network.result()
    subnet = network_client.subnets.create_or_update(
        resource_group_name=resource_group_name,
        virtual_network_name=virtual_network_name,
        subnet_name=subnet_name,
        subnet_parameters=Subnet(
            address_prefix='10.0.0.0/24'
        )
    )
    return subnet.result().id


def create_aad_user(credentials, tenant_id, **kwargs):
    """
        Create an AAD application and service principal
        :param credentials: msrestazure.azure_active_directory.AdalAuthentication
        :param tenant_id: str
        :param **application_name: str
    """
    graph_rbac_client = GraphRbacManagementClient(
        credentials,
        tenant_id,
        base_url=AZURE_PUBLIC_CLOUD.endpoints.active_directory_graph_resource_id
    )
    application_credential = uuid.uuid4()
    try:
        display_name = kwargs.get("application_name", DefaultSettings.application_name)
        application = graph_rbac_client.applications.create(
            parameters=ApplicationCreateParameters(
                available_to_other_tenants=False,
                identifier_uris=["http://{}.com".format(display_name)],
                display_name=display_name,
                password_credentials=[
                    PasswordCredential(
                        end_date=datetime(2299, 12, 31, 0, 0, 0, 0, tzinfo=timezone.utc),
                        value=application_credential,
                        key_id=uuid.uuid4()
                    )
                ]
            )
        )
        service_principal = graph_rbac_client.service_principals.create(
            ServicePrincipalCreateParameters(
                app_id=application.app_id,
                account_enabled=True
            )
        )
    except GraphErrorException as e:
        if e.inner_exception.code == "Request_BadRequest":
            application = next(graph_rbac_client.applications.list(
                filter="identifierUris/any(c:c eq 'http://{}.com')".format(display_name)))

            confirmation_prompt = "Previously created application with name {} found. "\
                                  "Would you like to use it? (y/n): ".format(application.display_name)
            prompt_for_confirmation(confirmation_prompt, e, ValueError("Response not recognized. Please try again."))

            service_principal = next(graph_rbac_client.service_principals.list(
                filter="appId eq '{}'".format(application.app_id)))
        else:
            raise e

    return application.app_id, service_principal.object_id, str(application_credential)


def create_role_assignment(credentials, subscription_id, scope, principal_id):
    """
        Gives service principal contributor role authorization on scope
        :param credentials: msrestazure.azure_active_directory.AdalAuthentication
        :param subscription_id: str
        :param scope: str
        :param principal_id: str
    """
    authorization_client = AuthorizationManagementClient(credentials, subscription_id)
    role_name = 'Contributor'
    roles = list(authorization_client.role_definitions.list(
        scope,
        filter="roleName eq '{}'".format(role_name)
    ))
    contributor_role = roles[0]
    for i in range(10):
        try:
            authorization_client.role_assignments.create(
                scope,
                uuid.uuid4(),
                {
                    'role_definition_id': contributor_role.id,
                    'principal_id': principal_id
                }
            )
            break
        except CloudError as e:
            # ignore error if service principal has not yet been created
            time.sleep(1)
            if i == 10:
                raise e


def format_secrets(**kwargs):
    '''
    Returns the secrets for the created resources to be placed in credentials.json
    The following form is returned:

        service_principal:
            tenant_id: <AAD Diretory ID>
            client_id: <AAD App Application ID>
            credential: <AAD App Password>
            batch_account_resource_id: </batch/account/resource/id>
            storage_account_resource_id: </storage/account/resource/id>
    '''
    return json.dumps({"service_principal": kwargs}, indent = 4)


def prompt_for_confirmation(prompt, deny_error, unrecognized_input_error):
    """
        Prompt user for confirmation, 'y' for confirm, 'n' for deny
        :param prompt: str
        :param deny_error: Exception
        :param unrecognized_input_error: Exception
        :return None if prompt successful, else raises error
    """
    confirmation = input(prompt).lower()
    for i in range(3):
        if confirmation == "n":
            raise deny_error
        elif confirmation == "y":
            break
        elif confirmation != "y" and i == 2:
            raise unrecognized_input_error
        confirmation = input("Please input 'y' or 'n': ").lower()


def prompt_with_default(key, value):
    user_value = input("{0} [{1}]: ".format(key, value))
    if user_value != "":
        return user_value
    else:
        return value


def prompt_tenant_selection(tenant_ids):
    print("Multiple tenants detected. Please input the ID of the tenant you wish to use.")
    print("Tenants:", ", ".join(tenant_ids))
    given_tenant_id = input("Please input the ID of the tenant you wish to use: ")
    for i in range(3):
        if given_tenant_id in tenant_ids:
            return given_tenant_id
        if i != 2:
            given_tenant_id = input("Input not recognized, please try again: ")
    raise AccountSetupError("Tenant selection not recognized after 3 attempts.")



class Spinner:
    busy = False
    delay = 0.1

    @staticmethod
    def spinning_cursor():
        while 1:
            for cursor in '|/-\\': yield cursor

    def __init__(self, delay=None):
        self.spinner_generator = self.spinning_cursor()
        if delay and float(delay): self.delay = delay

    def __enter__(self):
        return self.start()

    def __exit__(self, exc_type, exc_val, exc_tb):
        return self.stop()

    def spinner_task(self):
        while self.busy:
            sys.stdout.write(next(self.spinner_generator))
            sys.stdout.flush()
            time.sleep(self.delay)
            sys.stdout.write('\b')
            sys.stdout.flush()

    def start(self):
        self.busy = True
        threading.Thread(target=self.spinner_task, daemon=True).start()

    def stop(self):
        self.busy = False
        time.sleep(self.delay)



if __name__ == "__main__":
    print("\nGetting credentials.")
    # get credentials and tenant_id
    creds, subscription_id = credentials.get_azure_cli_credentials()
    subscription_client = SubscriptionClient(creds)
    tenant_ids = [tenant.id for tenant in subscription_client.tenants.list()]
    if len(tenant_ids) != 1:
        tenant_id = prompt_tenant_selection(tenant_ids)
    else:
        tenant_id = tenant_ids[0]

    print("Input the desired names and values for your Azure resources. "\
          "Default values are provided in the brackets. "\
          "Hit enter to use default.")

    authentication = prompt_with_default("Enter 1 for Shared Key Authentication, 2 for Azure Active Directory Authentication", DefaultSettings.authentication)
    if authentication == DefaultSettings.authentication:
        kwargs = {
            "region": prompt_with_default("Azure Region", DefaultSettings.region),
            "resource_group": prompt_with_default("Resource Group Name", DefaultSettings.resource_group),
            "storage_account": prompt_with_default("Storage Account Name", DefaultSettings.storage_account),
            "batch_account": prompt_with_default("Batch Account Name", DefaultSettings.batch_account),
            # "virtual_network_name": prompt_with_default("Virtual Network Name", DefaultSettings.virtual_network_name),
            # "subnet_name": prompt_with_default("Subnet Name", DefaultSettings.subnet_name),
        }
    else:
        kwargs = {
            "region": prompt_with_default("Azure Region", DefaultSettings.region),
            "resource_group": prompt_with_default("Resource Group Name", DefaultSettings.resource_group),
            "storage_account": prompt_with_default("Storage Account Name", DefaultSettings.storage_account),
            "batch_account": prompt_with_default("Batch Account Name", DefaultSettings.batch_account),
            # "virtual_network_name": prompt_with_default("Virtual Network Name", DefaultSettings.virtual_network_name),
            # "subnet_name": prompt_with_default("Subnet Name", DefaultSettings.subnet_name),
            "application_name": prompt_with_default("Active Directory Application Name", DefaultSettings.application_name),
            "application_credential_name": prompt_with_default("Active Directory Application Credential Name", DefaultSettings.resource_group),
            "service_principal": prompt_with_default("Service Principal Name", DefaultSettings.service_principal)
        }

    print("Creating the Azure resources.")

    # create resource group
    with Spinner():
        resource_group_id = create_resource_group(creds, subscription_id, **kwargs)
        kwargs["resource_group_id"] = resource_group_id
    print("Created resource group.")

    # create storage account
    with Spinner():
        storage_account_id = create_storage_account(creds, subscription_id, **kwargs)
        kwargs["storage_account_id"] = storage_account_id
    print("Created Storage account.")

    # create batch account
    with Spinner():
        batch_account_id = create_batch_account(creds, subscription_id, **kwargs)
    print("Created Batch account.")

    # create vnet with a subnet
    # subnet_id = create_vnet(creds, subscription_id)

    if authentication == DefaultSettings.authentication:
        # retrieve batch account key
        with Spinner():
            batch_account_key = batch_account_get_keys(creds, subscription_id, **kwargs)
            kwargs["batch_account_key"] = batch_account_key
        print("Retrieved batch account key.")

        with Spinner():
            storage_account_keys = storage_account_get_keys(creds, subscription_id, **kwargs)
            kwargs["storage_account_key"] = storage_account_keys
        print("Retrieved storage account key.")

        secrets = format_secrets(
            **{
                "batchAccount": {
                  "name": kwargs["batch_account"],
                  "key": "{}".format(kwargs["batch_account_key"]),
                  "url": "{}".format("batchaccounturl")
                },
                "storageAccount": {
                  "name": kwargs["storage_account"],
                  "key": "{}".format(kwargs["storage_account_key"]),
                  "endpointSuffix": "{}".format("core.windows.net")
                }
            }
        )
    else:
        # create AAD application and service principal
        with Spinner():
            profile = credentials.get_cli_profile()
            aad_cred, subscirption_id, tenant_id = profile.get_login_credentials(
                resource=AZURE_PUBLIC_CLOUD.endpoints.active_directory_graph_resource_id
            )

            application_id, service_principal_object_id, application_credential = create_aad_user(aad_cred, tenant_id, **kwargs)
        print("Created Azure Active Directory service principal.")

        with Spinner():
            create_role_assignment(creds, subscription_id, resource_group_id, service_principal_object_id)
        print("Configured permsisions.")

        secrets = format_secrets(
            **{
                '"servicePrincipal"': {
                  '"tenant_id"': '"{}"'.format(tenant_id),
                  '"client_id"': '"{}"'.format(application_id),
                  '"credential"': '"{}"'.format(application_credential),
                  '"batchAccountResourceId"': '"{}"'.format(batch_account_id),
                  '"storageAccountResourceId"': '"{}"'.format(storage_account_id)
                }
            }
        )

    print("\n# Copy the following into your credentials.json file\n{}".format(secrets))

