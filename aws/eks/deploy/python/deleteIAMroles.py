import boto3

def detach_and_delete_policies():
    # Create an IAM client
    iam = boto3.client('iam')

    # List all IAM policies
    response = iam.list_policies(Scope='Local')
    policies = response['Policies']

    # Detach and delete each policy
    for policy in policies:
        policy_arn = policy['Arn']
        policy_name = policy['PolicyName']

        # Detach the policy from all entities (users, groups, and roles)
        response = iam.list_entities_for_policy(PolicyArn=policy_arn)
        entities = response['PolicyUsers'] + response['PolicyGroups'] + response['PolicyRoles']

        for entity in entities:
            entity_type = entity['Type']
            entity_name = entity['EntityName']

            if entity_type == 'USER':
                iam.detach_user_policy(UserName=entity_name, PolicyArn=policy_arn)
            elif entity_type == 'GROUP':
                iam.detach_group_policy(GroupName=entity_name, PolicyArn=policy_arn)
            elif entity_type == 'ROLE':
                iam.detach_role_policy(RoleName=entity_name, PolicyArn=policy_arn)

        # Delete the policy
        iam.delete_policy(PolicyArn=policy_arn)

        print(f"Detached and deleted policy: {policy_name}")

# Call the function to detach and delete policies
detach_and_delete_policies()

