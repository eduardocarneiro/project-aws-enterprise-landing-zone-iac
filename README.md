# Project Marruá: Automated Enterprise AWS Landing Zone & Core Infrastructure

[![Infrastructure as Code](https://img.shields.io/badge/IaC-Terraform-blueviolet?style=flat-square&logo=terraform)](https://www.terraform.io/)
[![AWS Architecture](https://img.shields.io/badge/AWS-Multi--Account-orange?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/)
[![Governance](https://img.shields.io/badge/Governance-Control%20Tower-blue?style=flat-square)](https://aws.amazon.com/controltower/)

## 📋 Project Overview
Project Marruá simulates a production-grade, enterprise-scale AWS multi-account environment built from the ground up using Infrastructure as Code (IaC). This repository demonstrates how to architect a secure, scalable, and compliant AWS Landing Zone using **AWS Organizations**, **AWS Control Tower**, and **IAM Identity Center**, managed completely via **Terraform**.

To demonstrate advanced cloud engineering capabilities while remaining cost-conscious on a personal AWS account, this implementation focuses deeply on two primary pillars of the environment:
1. **The Core Network Account** (The central infrastructure hub).
2. **The App1 Dev Account** (A decentralized application workload spoke).

---

## 🏗️ Architecture Design
The infrastructure leverages a **Hub-and-Spoke networking topology** alongside an AWS-recommended multi-account strategy to enforce strong isolation boundaries for security, billing, and resource limits.

### Multi-Account Organization Structure
<pre>
                              AWS ORGANIZATION
                                        │
 ┌──────────────────────────────────────┼──────────────────────────────────────┐
 │                                      │                                      │
 │                                      │                                      │
 Security OU                      Infrastructure OU                      Workloads OU
 │                                      │                                      │
 │                                      │                                      │
 ├── Log Archive                        ├── Network Account                    ├── DEV OU
 ├── Audit Account                      │   ├── Transit Gateway                │    │
 ├── Security Tooling                   │   ├── VPN Site-to-Site               │    ├── App1 Account
 └── Compliance                         │   ├── Route 53 Private Hosted Zone   │────┤
                                        │   └── Compliance                     │    └── App2 Account
                                        │                                      │ 
                                        ├── Shared Services                    ├── QA OU
                                        ├── Identity Account                   └── Prod OU
                                        └── CI/CD Account                      
</pre>

* **Management Account:** Reserved strictly for consolidated billing and organization governance. No application workloads run here.
* **Security OU:** * `Log Archive Account`: Centralized, immutable storage for CloudTrail, Config, and VPC Flow Logs.
  * `Audit Account`: Central compliance scanning and auditing (AWS Config, Security Hub).
* **Infrastructure OU:**
  * `Network Account` **[Implementation Focus]**: Manages ingress/egress traffic, cross-account routing, and centralized DNS.
  * `CI/CD Account`: Houses GitOps deployment pipelines.
* **Workloads OU (Nested Environments):**
  * `DEV OU` ➔ `App1 Dev Account` **[Implementation Focus]**: Sandbox/Development space for individual application workloads.

---

## 🌐 Deep Dive: Network & Application Integration

This project implements a secure, cross-account private DNS and connectivity resolution model between the central Network Hub and the Application Spoke.


### 1. Central Network Account (The Hub)
* **AWS Transit Gateway (TGW):** Acts as a cloud router to interconnect VPCs across different AWS accounts seamlessly.
* **AWS Site-to-Site VPN:** Provisioned via Terraform to simulate encrypted on-premises connectivity to the cloud environment.
* **Route 53 Central Private Hosted Zone (PHZ):** Houses the primary enterprise internal root domain (e.g., `corp.internal`).

### 2. App1 Dev Account (The Spoke)
* **Isolated Workload VPC:** An application VPC containing isolated private subnets, decoupled from external network access.
* **Route 53 Subdomain Delegation:** A local Private Hosted Zone managing `app1.dev.corp.internal`.
* **Cross-Account DNS Resolution:** Implements Route 53 **VPC Association Authorizations** to bind the App1 Dev subdomain zone with the central Network Account's VPCs, allowing seamless private DNS lookup without traversing the public internet.

---

## 🛠️ Tech Stack & Tooling
* **Cloud Provider:** Amazon Web Services (AWS)
* **Governance & Automation:** AWS Control Tower, AWS Organizations, IAM Identity Center (Federated SSO)
* **Infrastructure as Code:** Terraform (using S3 and DynamoDB for secure cross-account state-locking)
* **CI/CD / GitOps:** GitLab CI/CD configured via OpenID Connect (OIDC) for passwordless role-assumption.

---

## 🚀 Deployment Strategy & Cost Optimization

> ⚠️ **Cost Optimization Note:** To keep this personal simulation cost-free or low-cost, expensive persistent networking components (like AWS Transit Gateway and Site-to-Site VPN) are designed to be short-lived. 

The execution pipeline follows a strict **"Deploy, Document, and Destroy"** pattern:
1. **Plan:** Review resource execution charts using `terraform plan`.
2. **Deploy:** Execute `terraform apply` to dynamically spin up the landing zone, network hub, and application spokes.
3. **Verify & Document:** Collect architectural proof, routing table verification metrics, and deployment screenshots for portfolio verification.
4. **Tear Down:** Execute `terraform destroy` on the networking infrastructure blocks immediately following verification to eliminate hourly provisioning charges.

---

## 📂 Repository Structure
```text
├── terraform/
│   ├── bootstrap/          # Configures OIDC, S3 state backend, and basic IAM roles
│   ├── management/         # AWS Organizations & Control Tower baseline structures
│   ├── network/            # TGW, VPN, Route 53 Central Hub configurations (Target Focus)
└── documentation/          # Architecture diagrams, validation metrics, and screenshots
```