#!/bin/bash
set -euo pipefail

echo "Starting aggressive AWS VPC cleanup..."

# Delete all VPC peering connections
for pcx in $(aws ec2 describe-vpc-peering-connections --query "VpcPeeringConnections[].VpcPeeringConnectionId" --output text); do
  echo "Deleting VPC Peering Connection: $pcx"
  aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id "$pcx"
done

# List all non-default VPCs
for vpc in $(aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`false\`].VpcId" --output text); do
  echo "Cleaning up VPC: $vpc"

  # Delete NAT Gateways
  for nat in $(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$vpc --query "NatGateways[].NatGatewayId" --output text); do
    echo "Deleting NAT Gateway: $nat"
    aws ec2 delete-nat-gateway --nat-gateway-id "$nat" || true
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$nat" || true
  done

  # Release EIPs
  for alloc in $(aws ec2 describe-addresses --filters Name=domain,Values=vpc --query "Addresses[?VpcId=='$vpc'].AllocationId" --output text); do
    echo "Releasing EIP: $alloc"
    aws ec2 release-address --allocation-id "$alloc" || true
  done

  # Detach and delete IGWs
  for igw in $(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$vpc --query "InternetGateways[].InternetGatewayId" --output text); do
    echo "Detaching and deleting IGW: $igw"
    aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" || true
    aws ec2 delete-internet-gateway --internet-gateway-id "$igw" || true
  done

  # Delete subnets
  for subnet in $(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc --query "Subnets[].SubnetId" --output text); do
    echo "Deleting subnet: $subnet"
    aws ec2 delete-subnet --subnet-id "$subnet" || true
  done

  # Delete route tables (except main)
  for rtb in $(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[?Associations[?Main!=\`true\`]].RouteTableId" --output text); do
    echo "Deleting route table: $rtb"
    aws ec2 delete-route-table --route-table-id "$rtb" || true
  done

  # Delete security groups (except default)
  for sg in $(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc --query "SecurityGroups[?GroupName!='default'].GroupId" --output text); do
    echo "Deleting security group: $sg"
    aws ec2 delete-security-group --group-id "$sg" || true
  done

  # Delete network interfaces
  for eni in $(aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=$vpc --query "NetworkInterfaces[].NetworkInterfaceId" --output text); do
    echo "Deleting network interface: $eni"
    aws ec2 delete-network-interface --network-interface-id "$eni" || true
  done

  # Delete VPC endpoints
  for vpce in $(aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=$vpc --query "VpcEndpoints[].VpcEndpointId" --output text); do
    echo "Deleting VPC endpoint: $vpce"
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$vpce" || true
  done

  # Try to delete the VPC, retrying if dependencies remain
  for attempt in {1..5}; do
    echo "Attempting to delete VPC: $vpc (try $attempt)"
    if aws ec2 delete-vpc --vpc-id "$vpc"; then
      echo "Deleted VPC: $vpc"
      break
    else
      echo "VPC $vpc could not be deleted, checking for remaining dependencies..."
      # Delete any remaining ENIs
      for eni in $(aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=$vpc --query "NetworkInterfaces[].NetworkInterfaceId" --output text); do
        echo "Deleting network interface: $eni"
        aws ec2 delete-network-interface --network-interface-id "$eni" || true
      done
      # Delete any remaining VPC endpoints
      for vpce in $(aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=$vpc --query "VpcEndpoints[].VpcEndpointId" --output text); do
        echo "Deleting VPC endpoint: $vpce"
        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$vpce" || true
      done
      sleep 10
    fi
  done
done

echo "AWS VPC cleanup complete."
