# 🏗️ CloudMason: GitOps & Infrastructure Repository

Welcome to the infrastructure and continuous deployment (GitOps) repository for **CloudMason**, the AI-Powered Enterprise Architecture & Automation Platform.

This repository represents the **Desired State** of our entire cloud infrastructure and Kubernetes (K3s) cluster. It operates on a "Two-Repo" architecture, strictly separating infrastructure definitions from microservice application code.

## 📐 Architecture Overview

- **App Repo (`cloudmason-services`)**: Contains the source code for the 12 microservices (Go, Node.js, Python). CI pipelines build Docker images and push them to the registry.
- **GitOps Repo (`cloudmason-gitops` - *This Repo*)**: Contains Terraform code for provisioning servers and Argo CD / Kubernetes manifests for deploying the applications and databases.

## 📂 Directory Structure

```text
cloudmason-gitops/
├── terraform/                  # Infrastructure as Code (IaC)
│   ├── environments/           # Dev, Prod environment states and variables
│   └── modules/                # Reusable Terraform modules (K3s, Network, DB)
├── kubernetes/                 # Kubernetes Manifests & GitOps State
│   ├── argocd-install/         # Argo CD bootstrap manifests
│   ├── infrastructure/         # Core services (RabbitMQ, Postgres, Redis, MongoDB, Loki)
│   └── apps/                   # Argo CD Application manifests for the 12 CloudMason microservices
