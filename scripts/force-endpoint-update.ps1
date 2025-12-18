#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Force update EKS cluster endpoints to enable public access
.DESCRIPTION
    Updates existing EKS clusters to enable public endpoint access for CI/CD
#>

Write-Host "Forcing EKS endpoint updates..." -ForegroundColor Yellow

# Update backend cluster endpoint
Write-Host "Updating eks-backend endpoint configuration..." -ForegroundColor Cyan
aws eks update-cluster-config --name eks-backend --resources-vpc-config endpointPublicAccess=true,endpointPrivateAccess=true

# Update gateway cluster endpoint  
Write-Host "Updating eks-gateway endpoint configuration..." -ForegroundColor Cyan
aws eks update-cluster-config --name eks-gateway --resources-vpc-config endpointPublicAccess=true,endpointPrivateAccess=true

Write-Host "Endpoint updates initiated. Wait 5-10 minutes for completion." -ForegroundColor Green
Write-Host "Monitor with: aws eks describe-cluster --name [cluster-name] --query 'cluster.status'" -ForegroundColor White