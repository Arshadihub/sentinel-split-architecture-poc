# sentinel-split-architecture-poc

## Overview
This repo demonstrates a split architecture with:
- Gateway VPC + EKS cluster (public proxy)
- Backend VPC + EKS cluster (internal service)
- Secure VPC peering and restricted SGs
- CI/CD via GitHub Actions

## Setup
1. Clone repo locally.
2. Configure AWS credentials in GitHub Secrets.
3. Run Terraform via GitHub Actions.
4. Deploy Kubernetes manifests.

## Networking
- Gateway and backend VPCs in us-east-1.
- VPC peering for private communication.
- Backend service restricted to gateway cluster.

## Next Steps
- Add TLS/mTLS.
- Observability stack.
- GitOps with ArgoCD.
