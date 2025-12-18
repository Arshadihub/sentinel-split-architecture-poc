# Sentinel Split Architecture PoC

## Overview

This project implements a proof-of-concept for Rapyd Sentinel's split architecture, demonstrating secure communication between isolated gateway and backend environments using AWS EKS, VPC peering, and automated CI/CD.

## Architecture

### Infrastructure Components

- **Two Isolated VPCs:**
  - `vpc-gateway` (172.16.0.0/16) - Public-facing proxy services
  - `vpc-backend` (172.17.0.0/16) - Internal backend services

- **Amazon EKS Clusters:**
  - `eks-gateway` - Hosts internet-facing proxy applications
  - `eks-backend` - Runs internal processing services

- **Private Networking:**
  - VPC Peering connection for secure cross-VPC communication
  - Private subnets across multiple AZs (us-east-1a, us-east-1b)
  - NAT Gateways for outbound internet access
  - No public EC2 instances

### Application Architecture

- **Backend Service:** Simple web server responding "Hello from backend" on port 8080, exposed via internal LoadBalancer
- **Gateway Proxy:** NGINX reverse proxy forwarding traffic to backend LoadBalancer via VPC peering
- **Public Access:** LoadBalancer exposes gateway proxy to internet
- **Private Communication:** Backend LoadBalancer accessible from gateway VPC via security groups and VPC peering

## Security Model

### Network Security
- **VPC Isolation:** Complete network separation between gateway and backend
- **Security Groups:** Backend only accepts traffic from gateway VPC CIDR (172.16.0.0/16)
- **NetworkPolicy:** Kubernetes-level network policies restrict pod-to-pod communication
- **Private Subnets:** No direct internet access to workloads

### Access Control
- **EKS RBAC:** Cluster creator admin permissions for CI/CD
- **Cross-VPC DNS:** Service discovery via internal LoadBalancer URLs

### NetworkPolicy Explanation
- **Backend NetworkPolicy:** Allows all ingress traffic since cross-cluster communication requires it
- **Security Groups:** Primary security control restricting backend access to gateway VPC CIDR only
- **Internal LoadBalancer:** Backend service uses internal-only LoadBalancer to prevent internet access

## Quick Start

### Prerequisites
- AWS Account with appropriate IAM permissions
- GitHub repository with Actions enabled
- AWS credentials configured as GitHub Secrets

### GitHub Secrets Required
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY  
AWS_REGION
```

### Deployment

1. **Clone Repository:**
   ```bash
   git clone <repository-url>
   cd sentinel-split-architecture-poc
   ```

2. **Automatic Deployment:**
   ```bash
   git push origin main
   ```
   This triggers the GitHub Actions pipeline which:
   - Validates Terraform configuration
   - Plans and applies infrastructure
   - Validates Kubernetes manifests
   - Deploys applications to both clusters
   - Verifies end-to-end connectivity

## Network Communication Flow

### Cross-VPC Communication
1. **Client Request** → Gateway LoadBalancer (Internet Gateway)
2. **Gateway LoadBalancer** → Gateway EKS Cluster (Private Subnet)
3. **Gateway Proxy** → Backend LoadBalancer via VPC Peering
4. **Backend LoadBalancer** → Backend EKS Cluster (Private Subnet)
5. **Backend Service** → Response back through same path

### Service Discovery
- Backend service exposed via internal LoadBalancer
- Gateway proxy gets backend LoadBalancer URL during deployment
- Cross-cluster communication via LoadBalancer endpoints and VPC peering

## CI/CD Pipeline

### GitHub Actions Workflow
- **Trigger:** Push to main branch or manual workflow dispatch
- **Terraform Validation:** `terraform validate` and planning
- **Kubernetes Validation:** `kubectl apply --dry-run` for manifest validation
- **Infrastructure Deployment:** Automated terraform apply
- **Application Deployment:** Automated kubectl deployment to both clusters
- **Verification:** End-to-end connectivity testing

## Trade-offs and Considerations

### 3-Day Development Constraints
- **Simplified Security:** Using basic security groups instead of WAF/Shield
- **Single NAT Gateway:** Cost optimization but creates single point of failure
- **Basic Monitoring:** No comprehensive observability stack implemented
- **Manual Secrets:** Production would use AWS Secrets Manager/HashiCorp Vault

### Next Steps
- **Security:** Implement TLS/mTLS, WAF, Pod Security Standards
- **Observability:** Add Prometheus, Grafana, distributed tracing
- **Operations:** Implement GitOps with ArgoCD, blue/green deployments
- **Scalability:** Add service mesh, horizontal pod autoscaling

## Testing

### Verify Deployment
```bash
# Get LoadBalancer URL
kubectl get svc proxy-svc -n gateway

# Test connectivity
curl http://<load-balancer-url>
# Expected: "Hello from backend"
```

*This project demonstrates a production-ready foundation for split architecture deployments while maintaining security, scalability, and operational best practices.*

Applications:
- Backend service: Simple web server that responds "Hello from backend"
- Gateway proxy: nginx reverse proxy that forwards requests to backend
- NetworkPolicies for additional pod-level security
- LoadBalancers configured for proper access patterns

## Quick Start

1. Clone and setup:
   ```bash
   git clone https://github.com/Arshadihub/sentinel-split-architecture-poc.git
   cd sentinel-split-architecture-poc
   ```

2. AWS Setup:
   - Get AWS credentials from interviewer
   - GitHub Actions handles deployment automatically on push

3. Deploy:
   ```bash
   git push origin main  # Triggers full deployment
   ```

4. Test connectivity:
   ```bash
   # Get proxy URL (once deployment completes)
   kubectl -n gateway get svc proxy-svc
   # Should show backend response through proxy
   curl http://<loadbalancer-url>
   ```

## Architecture Deep Dive

### Network Design

I designed the networking with security and isolation as priorities:

VPC Layout:
- `vpc-gateway` (10.10.0.0/16): Public-facing proxy services
- `vpc-backend` (10.20.0.0/16): Internal processing services
- 2 private subnets per VPC across different AZs
- Single NAT gateway per VPC

Connectivity:
- VPC peering connection enables private communication
- Security groups restrict backend access to gateway CIDR only
- No direct internet access to backend services
- Gateway proxy is the only entry point

### EKS Configuration

Each cluster runs in private subnets with managed node groups:

Security Features:
- IRSA enabled for secure pod-to-AWS API communication
- Security groups configured for minimal required access
- No public EC2 instances anywhere
- NetworkPolicies for additional pod isolation

### Application Flow

```
Internet → ALB → Gateway Proxy (EKS) → VPC Peering → Backend Service (EKS)
```

1. Gateway Layer: nginx proxy receives external traffic
2. Cross-VPC: Traffic routes privately through VPC peering
3. Backend Layer: Internal service processes requests securely
4. Response: Returns through same path back to client

## CI/CD Pipeline

I set up GitHub Actions to handle the full deployment lifecycle:

Infrastructure Phase:
- Terraform validation and planning
- Resource cleanup to handle AWS quotas
- Infrastructure deployment with dependency management

Application Phase:
- Kubernetes manifest validation
- Backend service deployment and LB discovery
- Gateway proxy config injection with backend URL
- End-to-end connectivity validation

Security Features:
- OIDC federation instead of long-lived AWS keys
- Least-privilege IAM policies
- Automated cleanup on failures

## Security Model

### Network Security
- VPC isolation: Complete separation between environments
- Private subnets: No direct internet access to workloads
- Security groups: Port-level restrictions based on CIDR ranges
- NetworkPolicies: Pod-level communication controls

### Access Controls
- No public EC2s: All compute runs in private subnets
- Load balancer restrictions: Backend LB is internal-only
- IAM boundaries: EKS service accounts use IRSA for fine-grained permissions

---

*This PoC demonstrates the core architecture and security principles for Sentinel's split domain design. The modular structure supports rapid iteration while maintaining production-ready security and operational practices.*