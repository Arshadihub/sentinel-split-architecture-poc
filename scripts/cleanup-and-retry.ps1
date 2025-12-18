#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cleanup failed EKS resources and retry deployment
.DESCRIPTION
    Removes failed EKS node groups and other conflicting resources to allow clean redeployment
#>

param(
    [string]$Region = "us-east-1",
    [string]$Profile = "default"
)

Write-Host "🧹 Starting cleanup of failed EKS resources..." -ForegroundColor Yellow

# Set AWS region
$env:AWS_DEFAULT_REGION = $Region

# Function to safely delete EKS node group
function Remove-EKSNodeGroup {
    param($ClusterName, $NodeGroupName)
    
    try {
        Write-Host "Checking node group: $NodeGroupName in cluster: $ClusterName"
        
        $nodeGroup = aws eks describe-nodegroup --cluster-name $ClusterName --nodegroup-name $NodeGroupName --output json 2>$null | ConvertFrom-Json
        
        if ($nodeGroup) {
            $status = $nodeGroup.nodegroup.status
            Write-Host "Node group status: $status" -ForegroundColor Cyan
            
            if ($status -in @("CREATE_FAILED", "DEGRADED", "ACTIVE")) {
                Write-Host "Deleting node group: $NodeGroupName" -ForegroundColor Red
                aws eks delete-nodegroup --cluster-name $ClusterName --nodegroup-name $NodeGroupName
                
                # Wait for deletion
                Write-Host "Waiting for node group deletion..." -ForegroundColor Yellow
                do {
                    Start-Sleep 30
                    $checkGroup = aws eks describe-nodegroup --cluster-name $ClusterName --nodegroup-name $NodeGroupName --output json 2>$null | ConvertFrom-Json
                    if ($checkGroup) {
                        Write-Host "Node group status: $($checkGroup.nodegroup.status)"
                    }
                } while ($checkGroup -and $checkGroup.nodegroup.status -eq "DELETING")
                
                Write-Host "Node group deleted successfully" -ForegroundColor Green
            }
        } else {
            Write-Host "Node group not found - already clean" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error checking/deleting node group: $_" -ForegroundColor Yellow
    }
}

# Function to delete security group if it exists
function Remove-SecurityGroup {
    param($GroupName, $VpcId)
    
    try {
        $sg = aws ec2 describe-security-groups --filters "Name=group-name,Values=$GroupName" "Name=vpc-id,Values=$VpcId" --output json 2>$null | ConvertFrom-Json
        
        if ($sg.SecurityGroups) {
            $sgId = $sg.SecurityGroups[0].GroupId
            Write-Host "Deleting security group: $GroupName ($sgId)" -ForegroundColor Red
            aws ec2 delete-security-group --group-id $sgId
            Write-Host "Security group deleted" -ForegroundColor Green
        } else {
            Write-Host "Security group $GroupName not found - already clean" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error deleting security group: $_" -ForegroundColor Yellow
    }
}

# Cleanup failed node groups
Write-Host "`nCleaning up EKS node groups..." -ForegroundColor Cyan
Remove-EKSNodeGroup -ClusterName "eks-gateway" -NodeGroupName "default-2025121620544954460000001c"
Remove-EKSNodeGroup -ClusterName "eks-backend" -NodeGroupName "default-20251216215722559100000015"

# Cleanup conflicting security groups  
Write-Host "`nCleaning up security groups..." -ForegroundColor Cyan
Remove-SecurityGroup -GroupName "backend-lb-sg" -VpcId "vpc-00d6478acab308f77"

Write-Host "`nCleanup completed!" -ForegroundColor Green
Write-Host "You can now retry the deployment with the fixes applied." -ForegroundColor White