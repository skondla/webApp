#/usr/bin/bash
# This script creates a service principal in Azure and assigns it a role to a specific resource group.
az --version
az login
az ad sp create-for-rbac   --role="Contributor" --scopes="/subscriptions/not45fgr-85ce-4064-85e0-somethingabc"

export TF_VAR_ARM_CLIENT_ID=appId
export TF_VAR_ARM_SUBSCRIPTION_ID=tenant
export TF_VAR_ARM_SUBSCRIPTION_ID=not45fgr-85ce-4064-85e0-somethingabc
export TF_VAR_ARM_CLIENT_SECRET=password

