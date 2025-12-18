<#
Imports existing CloudWatch Log Groups into Terraform state so Terraform
will manage them instead of failing with ResourceAlreadyExistsException.

Usage:
1. From repository root run: `terraform init` (if not already initialized)
2. Run this script in PowerShell: `./scripts/import-loggroups.ps1`

This script runs two `terraform import` commands targeting the
registry EKS module resources used in this repo.
#>

if ($env:TF_WORKING_DIR -and $env:TF_WORKING_DIR -ne "") {
	Write-Host "TF_WORKING_DIR detected; changing to Terraform config dir: $env:TF_WORKING_DIR"
	Set-Location -Path $env:TF_WORKING_DIR
} elseif ($env:GITHUB_WORKSPACE -and $env:GITHUB_WORKSPACE -ne "") {
	Write-Host "GITHUB_WORKSPACE detected; changing to repository root: $env:GITHUB_WORKSPACE"
	Set-Location -Path $env:GITHUB_WORKSPACE
} else {
	# When running locally, change to repo root (parent of scripts folder)
	Set-Location -Path (Resolve-Path -Path "$PSScriptRoot\..").Path
}

Write-Host "Running terraform init (if needed)..."
terraform init

# Check that VPC and peering resources exist in state (route tables must exist)
$vpcState = terraform state list | Select-String 'module.vpc_gateway|module.vpc_backend'
$peeringState = terraform state list | Select-String 'module.vpc_peering'
if (-not $vpcState -or -not $peeringState) {
	Write-Host "ERROR: VPC and peering resources must exist in Terraform state before importing log groups. Run the VPC and peering applies first."
	exit 1
}

Write-Host "Importing CloudWatch Log Group for eks-backend..."
terraform import "module.eks_backend.module.eks.aws_cloudwatch_log_group.this[0]" "/aws/eks/eks-backend/cluster"

Write-Host "Importing CloudWatch Log Group for eks-gateway..."
terraform import "module.eks_gateway.module.eks.aws_cloudwatch_log_group.this[0]" "/aws/eks-gateway/cluster"

Write-Host "Imports complete. Run 'terraform plan' to verify." 
