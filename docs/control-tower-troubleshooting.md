# Control Tower Troubleshooting Guide

This guide covers common issues when deploying AWS Control Tower, especially after a previous Control Tower landing zone has been decommissioned.

## Critical Pre-deployment Blockers

**Reference**: [AWS Control Tower Known Issues - Setup after decommissioning](https://docs.aws.amazon.com/en_us/controltower/latest/userguide/known-issues-decommissioning.html)

After decommissioning a Control Tower landing zone, you **cannot successfully deploy again** until manual cleanup is complete. The following conditions will cause deployment failures:

### 1. **Security/Sandbox OUs (CRITICAL BLOCKER)**
❌ **Blocker**: You cannot set up a new landing zone in an organization with top-level OUs named either `Security` or `Sandbox`.

**Resolution**: Rename or remove these OUs before attempting Control Tower deployment.

```bash
# Check for blocking OUs
aws organizations list-organizational-units \
  --parent-id $(aws organizations list-roots --query 'Roots[0].Id' --output text) \
  --query 'OrganizationalUnits[?Name==`Security` || Name==`Sandbox`]'

# If found, rename or delete them
aws organizations update-organizational-unit \
  --organizational-unit-id "ou-xxxxxxxxxx" \
  --name "SecurityOld"
```

### 2. **Control Tower IAM Roles and Policies**
❌ **Blocker**: These IAM roles and policies must be removed from the management account:

**Roles to remove**:
- `AWSControlTowerAdmin`
- `AWSControlTowerCloudTrailRole`
- `AWSControlTowerStackSetRole`
- `AWSControlTowerConfigAggregatorRoleForOrganizations`

**Policies to remove**:
- `AWSControlTowerAdminPolicy`
- `AWSControlTowerCloudTrailRolePolicy`
- `AWSControlTowerStackSetRolePolicy`

```bash
# Check for existing Control Tower roles
aws iam list-roles --query 'Roles[?starts_with(RoleName, `AWSControlTower`)].RoleName'

# Delete roles (example)
aws iam delete-role-policy --role-name AWSControlTowerAdmin --policy-name AWSControlTowerAdminPolicy
aws iam detach-role-policy --role-name AWSControlTowerAdmin --policy-arn arn:aws:iam::aws:policy/service-role/AWSControlTowerServiceRolePolicy
aws iam delete-role --role-name AWSControlTowerAdmin
```

### 3. **Reserved S3 Bucket Names**
❌ **Blocker**: These S3 buckets must not exist in the logging account:

- `aws-controltower-logs-{accountId}-{region}`
- `aws-controltower-s3-access-logs-{accountId}-{region}`

```bash
# Check for existing buckets (use logging account profile)
aws s3 ls s3://aws-controltower-logs-261503748007-us-gov-west-1 --profile your-logging-profile
aws s3 ls s3://aws-controltower-s3-access-logs-261503748007-us-gov-west-1 --profile your-logging-profile

# Remove buckets if they exist
aws s3 rb s3://aws-controltower-logs-261503748007-us-gov-west-1 --force --profile your-logging-profile
aws s3 rb s3://aws-controltower-s3-access-logs-261503748007-us-gov-west-1 --force --profile your-logging-profile
```

### 4. **CloudWatch Log Group**
❌ **Blocker**: The management account must not have the log group `aws-controltower/CloudTrailLogs`.

```bash
# Check for existing log group
aws logs describe-log-groups --log-group-name-prefix "aws-controltower/CloudTrailLogs"

# Delete if exists
aws logs delete-log-group --log-group-name "aws-controltower/CloudTrailLogs"
```

### 5. **Account Email Conflicts**
❌ **Blocker**: Email addresses specified for logging or audit accounts cannot be associated with existing AWS accounts.

**Resolution**: 
- Close the existing AWS accounts, OR
- Use different email addresses, OR  
- Use the "bring your own accounts" feature

### 6. **AWS Service Access (For New Regions)**
❌ **Blocker**: If setting up in a new AWS Region, disable Control Tower service access first:

```bash
aws organizations disable-aws-service-access --service-principal controltower.amazonaws.com
```

## Our Module's Built-in Validations

The Control Tower module includes pre-deployment checks for:
- ✅ Reserved S3 bucket names
- ✅ CloudWatch log group conflicts  
- ✅ Cross-account provider access

**Note**: The module does NOT automatically check for Security/Sandbox OUs or IAM role conflicts. These must be manually verified.

## Deployment States and Troubleshooting

### Check Landing Zone Status
```bash
# List existing landing zones
aws controltower list-landing-zones --region us-gov-west-1

# Check operations status
aws controltower list-landing-zone-operations --region us-gov-west-1

# Get operation details
aws controltower get-landing-zone-operation --operation-identifier "operation-id" --region us-gov-west-1
```

### Delete Failed Landing Zone
```bash
# Delete landing zone
aws controltower delete-landing-zone --landing-zone-identifier "landing-zone-id" --region us-gov-west-1

# Monitor delete operation
aws controltower get-landing-zone-operation --operation-identifier "delete-operation-id" --region us-gov-west-1
```

### Clean Terraform State
```bash
# Remove stale landing zone from state
tofu state rm "module.controltower.aws_controltower_landing_zone.this[0]"

# Verify state is clean
tofu state list | grep controltower
```

## Common Error Messages

### "User does not have permissions to access account data"
- **Cause**: Cross-account providers not configured or roles missing
- **Fix**: Verify `OrganizationAccountAccessRole` exists in target accounts

### "ValidationException: AWS Control Tower could not complete the operation, because it could not assume the AWSControlTowerAdmin role"
- **Cause**: Control Tower service roles missing or misconfigured
- **Fix**: Ensure all Control Tower service roles are created with correct policies

### "Resource was not found" (404 error)
- **Cause**: Stale Terraform state referencing deleted landing zone
- **Fix**: Remove stale resources from Terraform state

### "already exists" errors for S3 buckets
- **Cause**: Previous Control Tower deployment left behind S3 buckets
- **Fix**: Manually delete the reserved bucket names in the logging account

## Prevention and Best Practices

1. **Before destroying Control Tower**: Document all custom configurations
2. **Use proper decommissioning**: Use AWS Console decommissioning process when possible
3. **Verify cleanup**: Always run the manual cleanup checklist after decommissioning
4. **Test in non-production**: Validate the complete setup/teardown process in test environments
5. **Monitor operations**: Control Tower operations can take 30+ minutes - monitor progress

## Emergency Recovery

If Control Tower is in an inconsistent state:

1. **Stop all in-progress operations** (if possible)
2. **Clean up manually** using the checklist above
3. **Remove from Terraform state**: `tofu state rm` stale resources
4. **Wait 24-48 hours** before attempting re-deployment (AWS internal cleanup)
5. **Consider AWS Support** for complex stuck states

---

**Important**: Always review the [official AWS troubleshooting guide](https://docs.aws.amazon.com/en_us/controltower/latest/userguide/known-issues-decommissioning.html) for the most current information.
