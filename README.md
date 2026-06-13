# SAA Sprint Lab

A hands-on AWS Solutions Architect Associate (SAA-C03) study project. Each build
day adds a layer of production-shaped AWS infrastructure, applied through a real
CI/CD pipeline with no long-lived credentials anywhere.

The lab will host multiple apps over time. **FrontDesk** is the first: a guest
check-in system with S3 assets, an instance role, a database, and a public
endpoint. Each app is its own Terraform module and gets its own set of AWS
resources following the shared naming and security conventions established here.

---

## Architecture goal

A multi-AZ, auto-scaling two-tier architecture:

```
Internet -> CloudFront -> ALB (public subnets)
                          |
                     ASG / EC2 (private subnets, SSM only)
                          |
              RDS Multi-AZ PostgreSQL  +  DynamoDB (audit)
                          |
              S3 (assets)  +  EFS (shared uploads)
```

All encrypted at rest (CMK), all in transit (TLS), all accessed via instance
roles with no keys on disk anywhere.

---

## Current infrastructure

```
aws_saa-lab/
├── bootstrap/                  # Run ONCE locally. Creates HCP OIDC trust + IAM role.
│   ├── main.tf                 # HCP Terraform OIDC provider + saa-sprint-hcp-terraform role
│   ├── variables.tf            # github_org, github_repo, hcp_org, hcp_workspace (all defaulted)
│   ├── outputs.tf              # hcp_role_arn -> paste into HCP workspace env vars
│   └── versions.tf
├── infra/                      # Root stack. HCP Terraform runs here on every push.
│   ├── backend.tf              # HCP Terraform cloud backend (Hyfer-Org / aws_saa-lab)
│   ├── locals.tf               # Single source of truth: org=saa, app=frontdesk, tags
│   ├── versions.tf             # provider "aws" + default_tags driven by locals
│   ├── main.tf                 # Composes module "foundation" + module "frontdesk"
│   └── outputs.tf
├── modules/
│   ├── foundation/             # Shared platform: CMK (alias/saa-shared-cmk) + EBS default encryption
│   ├── secure-bucket/          # Reusable: versioned, public-blocked, SSE-KMS S3 bucket
│   ├── instance-role/          # Reusable: EC2 role + inline policy + SSM managed instance core
│   └── frontdesk/              # App layer: saa-frontdesk-assets bucket + saa-frontdesk-instance role
```

### What exists in AWS today

| Resource | Name | Purpose |
|---|---|---|
| KMS CMK | `alias/saa-shared-cmk` | Encrypts S3 objects and EBS volumes |
| EBS default encryption | region-wide | All new volumes encrypted with CMK automatically |
| S3 bucket | `saa-frontdesk-assets-<account_id>` | App asset storage, versioned, SSE-KMS |
| IAM role | `saa-frontdesk-instance` | EC2 instance role, least-priv to bucket + CMK + SSM |
| IAM OIDC provider | `app.terraform.io` | Lets HCP workers authenticate to AWS without keys |
| IAM role | `saa-sprint-hcp-terraform` | Assumed by HCP per run via short-lived JWT |

---

## Pipeline

```
Push to GitHub
      |
HCP Terraform detects change via webhook
      |
HCP worker assumes saa-sprint-hcp-terraform role via OIDC (no stored keys)
      |
terraform plan / apply against AWS
      |
State stored in HCP Terraform (Hyfer-Org / aws_saa-lab workspace)
```

PR triggers a speculative plan posted as a GitHub check. Merge to `main` triggers auto-apply.

---

## Bootstrap (run once)

Bootstrap creates the trust relationship between HCP Terraform and AWS. It runs
locally with your admin IAM credentials, the only time long-lived keys are used.

```bash
cd bootstrap
terraform init
terraform apply
```

Copy the `hcp_role_arn` output. In HCP workspace -> Variables add:

| Key | Value | Type |
|---|---|---|
| `TFC_AWS_PROVIDER_AUTH` | `true` | Environment |
| `TFC_AWS_RUN_ROLE_ARN` | *(output from above)* | Environment |

Delete your local AWS keys after bootstrap. Use AWS CloudShell for any future
bootstrap changes.

---

## Build roadmap

| Sprint | Focus | Key resources |
|---|---|---|
| ✅ | Pipeline | HCP Terraform, OIDC, state backend |
| ✅ | IAM & encryption | CMK, EBS defaults, S3 bucket, instance role |
| | VPC & networking | VPC, subnets, IGW, NAT GW, S3 gateway endpoint, SSM-only EC2 |
| | Compute | Launch template, ALB, ASG, FrontDesk app on EC2 |
| | Storage | S3 lifecycle to Glacier, EFS mount, versioned recovery |
| | Database | RDS Multi-AZ, Secrets Manager, DynamoDB audit table, Lambda |
| | Resilience | SQS, Route 53 failover, CloudWatch alarms |
| | Performance & cost | CloudFront, Spot/serverless, Trusted Advisor |

---

## Cost note: GitLab Ultimate as an alternative

This lab uses **GitHub + HCP Terraform**. For a real organisation, GitLab Ultimate
($99/user/year) is worth evaluating: it includes a built-in Terraform state
backend, eliminating the need for HCP Terraform entirely while keeping the same
keyless OIDC workflow.

GitLab CI/CD issues ID tokens (JWT) per pipeline run. The AWS trust policy points
to your GitLab instance instead of `app.terraform.io` and the pattern is identical
to what is built here. State is stored natively in GitLab with locking included.

At 200 developers: GitHub Enterprise + HCP Terraform + GitHub Advanced Security
runs approximately $15,000-$20,000/month. GitLab Ultimate SaaS covers the
equivalent for approximately $1,650/month. The architecture and security posture
are the same; the tooling cost is not.
