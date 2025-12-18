#!/bin/bash
    fi

# Robust VPC cleanup: strictly detach/delete all dependencies in correct order
# 1. Delete all VPC peering connections
for pcx in $(aws ec2 describe-vpc-peering-connections --query "VpcPeeringConnections[].VpcPeeringConnectionId" --output text); do
  echo "Deleting VPC Peering Connection: $pcx"
  aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id "$pcx"
done

# 2. For each non-default VPC, delete dependencies in order
for vpc in $(aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`false\`].VpcId" --output text); do
  echo "Cleaning up VPC: $vpc"

  # a. Delete NAT Gateways and wait
  for nat in $(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$vpc --query "NatGateways[].NatGatewayId" --output text); do
    echo "Deleting NAT Gateway: $nat"
    aws ec2 delete-nat-gateway --nat-gateway-id "$nat" || true
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$nat" || true
  done

  # b. Release EIPs (after NATs)
  for alloc in $(aws ec2 describe-addresses --filters Name=domain,Values=vpc --query "Addresses[?VpcId=='$vpc'].AllocationId" --output text); do
    echo "Releasing EIP: $alloc"
    aws ec2 release-address --allocation-id "$alloc" || true
  done

  # c. Detach and delete Internet Gateways
  for igw in $(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$vpc --query "InternetGateways[].InternetGatewayId" --output text); do
    echo "Detaching and deleting IGW: $igw"
    aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" || true
    aws ec2 delete-internet-gateway --internet-gateway-id "$igw" || true
  done

  # d. Delete route table associations (except main)
  for rtb in $(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].RouteTableId" --output text); do
    for assoc in $(aws ec2 describe-route-tables --route-table-ids $rtb --query "RouteTables[].Associations[?Main==\`false\`].RouteTableAssociationId" --output text); do
      if [ -n "$assoc" ]; then
        echo "Deleting route table association: $assoc"
        aws ec2 disassociate-route-table --association-id "$assoc" || true
      fi
    done
  done

  # e. Delete routes (except local) from all route tables
  for rtb in $(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].RouteTableId" --output text); do
    for route in $(aws ec2 describe-route-tables --route-table-ids $rtb --query "RouteTables[].Routes[?DestinationCidrBlock!='local'].DestinationCidrBlock" --output text); do
      if [ -n "$route" ]; then
        echo "Deleting route $route from route table $rtb"
        aws ec2 delete-route --route-table-id "$rtb" --destination-cidr-block "$route" || true
      fi
    done
  done

  # f. Delete subnets
  for subnet in $(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc --query "Subnets[].SubnetId" --output text); do
    echo "Deleting subnet: $subnet"
    aws ec2 delete-subnet --subnet-id "$subnet" || true
  done

  # g. Delete route tables (except main)
  for rtb in $(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[?Associations[?Main!=\`true\`]].RouteTableId" --output text); do
    echo "Deleting route table: $rtb"
    aws ec2 delete-route-table --route-table-id "$rtb" || true
  done

  # h. Delete VPC endpoints
  for vpce in $(aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=$vpc --query "VpcEndpoints[].VpcEndpointId" --output text); do
    echo "Deleting VPC endpoint: $vpce"
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$vpce" || true
  done

  # i. Delete network interfaces
  for eni in $(aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=$vpc --query "NetworkInterfaces[].NetworkInterfaceId" --output text); do
    echo "Deleting network interface: $eni"
    aws ec2 delete-network-interface --network-interface-id "$eni" || true
  done

  # j. Delete security groups (except default)
  for sg in $(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc --query "SecurityGroups[?GroupName!='default'].GroupId" --output text); do
    echo "Deleting security group: $sg"
    aws ec2 delete-security-group --group-id "$sg" || true
  done

  # Try to delete the VPC, retrying if dependencies remain
  for attempt in {1..5}; do
    echo "Attempting to delete VPC: $vpc (try $attempt)"
    if aws ec2 delete-vpc --vpc-id "$vpc"; then
      echo "Deleted VPC: $vpc"
      break
    else
      echo "VPC $vpc could not be deleted, checking for remaining dependencies..."
      sleep 10
    fi
  done
done

# Verify all non-default VPCs are deleted
remaining_vpcs=$(aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`false\`].VpcId" --output text)
if [ -n "$remaining_vpcs" ]; then
  echo "ERROR: The following non-default VPCs remain after cleanup: $remaining_vpcs"
  exit 1
else
  echo "All non-default VPCs have been deleted."
fi

  done
done

echo "AWS VPC cleanup complete."

# Verify all non-default VPCs are deleted
remaining_vpcs=$(aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`false\`].VpcId" --output text)
if [ -n "$remaining_vpcs" ]; then
  echo "ERROR: The following non-default VPCs remain after cleanup: $remaining_vpcs"
  exit 1
else
  echo "All non-default VPCs have been deleted."
fi
