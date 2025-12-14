<#
Run this script locally with your `sentinel-interview` profile to bootstrap the S3 backend,
DynamoDB lock table, OIDC provider, and an IAM role for GitHub Actions.

Usage:
  PowerShell> $env:AWS_PROFILE="sentinel-interview"; .\scripts\bootstrap-aws.ps1

It will print the Role ARN at the end — add that ARN to your repo secret `AWS_ROLE_TO_ASSUME`.

STOP if you see permission errors and paste them to your reviewer.
#>

Set-StrictMode -Version Latest

$bucket = "sentinel-split-architecture-poc-721500739616"
$dynamoTable = "terraform-locks"
$roleName = "GitHubActionsRole-sentinel-poc"
$accountId = "721500739616"

Write-Host "Creating S3 bucket: $bucket"
try {
  # us-east-1 create-bucket uses no LocationConstraint
  aws s3api create-bucket --bucket $bucket --region us-east-1 | Out-Null
} catch {
  Write-Warning "Create-bucket may have failed or bucket already exists: $_"
}

Write-Host "Putting encryption and public access block on bucket"
aws s3api put-bucket-encryption --bucket $bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket $bucket --public-access-block-configuration '{"BlockPublicAcls":true,"IgnorePublicAcls":true,"BlockPublicPolicy":true,"RestrictPublicBuckets":true}'

Write-Host "Creating DynamoDB table: $dynamoTable"
aws dynamodb create-table --table-name $dynamoTable --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region us-east-1 | Out-Null

Write-Host "Creating OIDC provider (may already exist)"
try {
  aws iam create-open-id-connect-provider --url "https://token.actions.githubusercontent.com" --client-id-list sts.amazonaws.com --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 | Out-Null
} catch {
  Write-Host "OIDC provider may already exist or creation failed: $_"
}

Write-Host "Generating trust policy file"
$trustFile = "iam/trust-policy-github-oidc.json"
if (-Not (Test-Path $trustFile)) { Write-Error "Trust policy file not found: $trustFile"; exit 1 }

Write-Host "Creating IAM role: $roleName"
try {
  aws iam create-role --role-name $roleName --assume-role-policy-document file://$trustFile | Out-Null
} catch {
  Write-Warning "Create-role may have failed or role may already exist: $_"
}

Write-Host "Attaching AdministratorAccess to role (for PoC). Replace with least-privilege later."
aws iam attach-role-policy --role-name $roleName --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

Write-Host "Role ARN:"
aws iam get-role --role-name $roleName --query 'Role.Arn' --output text

Write-Host "Bootstrap complete. Add the returned Role ARN to GitHub secret 'AWS_ROLE_TO_ASSUME'."
