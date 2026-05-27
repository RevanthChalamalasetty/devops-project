# DevOps Project

End-to-end production-grade CI/CD pipeline built on a home lab setup.

**Stack:** Java Spring Boot → GitHub → Jenkins → Docker → Trivy → ECR → Helm → ArgoCD → Kubernetes, with HashiCorp Vault for secrets and Prometheus/Grafana for observability.

---

## Architecture
Developer (Mac)
│
│ git push
▼
GitHub
│
│ webhook
▼
Jenkins (Ubuntu Laptop)
│
├── mvn clean verify      (Build & Test)
├── docker build           (Multi-stage Dockerfile)
├── trivy image scan       (Shift-left security)
├── docker push → ECR      (AWS Container Registry)
└── update helm/values.yaml (image tag commit)
│
│ ArgoCD polls every 3 min
▼
Kubernetes (Minikube / EKS)
│
├── spring-app pod     (Spring Boot REST API)
├── vault sidecar      (Secrets injection)
└── prometheus scrape  (Metrics collection)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Application | Java 21, Spring Boot 3.4.5, Maven 3.9 |
| CI Server | Jenkins (Ubuntu laptop, always on) |
| Containerisation | Docker, multi-stage builds |
| Security scanning | Trivy (CRITICAL CVE gate) |
| Container registry | AWS ECR |
| Infrastructure as Code | Terraform (AWS VPC, ECR, IAM) |
| Configuration management | Ansible |
| Kubernetes | Minikube (dev) / AWS EKS (prod) |
| Package manager | Helm |
| GitOps / CD | ArgoCD |
| Secrets management | HashiCorp Vault + Agent Injector |
| Monitoring | Prometheus + Grafana (kube-prometheus-stack) |
| Webhook tunnel | ngrok (laptop → GitHub) |

---

## Repository Structure
devops-project/
├── app/                          # Spring Boot application
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile                # Multi-stage build
├── ansible/                      # Server configuration
│   ├── inventory/
│   │   └── hosts.ini             # Git-ignored (contains IPs)
│   └── playbooks/
│       ├── site.yml              # Master playbook
│       ├── tools.yml             # Trivy, AWS CLI v2, Maven 3.9
│       └── configure.yml         # Jenkins docker group, dirs
├── helm/
│   └── spring-app/               # Helm chart
│       ├── Chart.yaml
│       ├── values.yaml           # Image tag updated by Jenkins
│       └── templates/
│           ├── deployment.yaml   # With Vault sidecar annotations
│           ├── service.yaml      # Named port for ServiceMonitor
│           ├── serviceaccount.yaml
│           ├── role.yaml         # Minimal RBAC
│           ├── rolebinding.yaml
│           ├── resourcequota.yaml
│           ├── limitrange.yaml
│           ├── hpa.yaml          # CPU-based autoscaling
│           ├── networkpolicy.yaml
│           ├── servicemonitor.yaml
│           └── ecr-token-refresh.yaml  # CronJob every 6h
├── infrastructure/
│   ├── bootstrap/
│   │   └── init.sh               # Creates S3 + DynamoDB for state
│   ├── terraform/
│   │   ├── persistent/           # VPC, ECR, IAM — never destroyed
│   │   └── cluster/              # EKS, NAT GW — destroy nightly
│   └── scripts/
│       ├── morning.sh            # terraform apply cluster/
│       └── evening.sh            # terraform destroy cluster/
├── jenkins/
│   └── Jenkinsfile               # Declarative pipeline
└── ARCHITECTURE.md               # Detailed architecture notes

---

## Pipeline Stages
Checkout → Build & Test → Docker Build → Trivy Scan → Push to ECR → Update Helm Chart

| Stage | Detail |
|---|---|
| Checkout | Clones repo, skips pipeline if commit is from Jenkins (`[skip ci]`) |
| Build & Test | `mvn clean verify` — compile, unit tests, package JAR |
| Docker Build | Multi-stage: JDK builder → JRE runtime (~200MB final image) |
| Trivy Scan | Fails pipeline on CRITICAL CVEs with available fixes |
| Push to ECR | Authenticates with temporary ECR credentials, pushes tagged image |
| Update Helm Chart | Commits new image tag to `values.yaml`, ArgoCD auto-syncs |

---

## Kubernetes Hardening

Every deployment includes:

- **RBAC** — dedicated ServiceAccount with read-only pod/service access
- **ResourceQuota** — namespace-level CPU/memory/pod caps
- **LimitRange** — default container resource limits
- **HPA** — scales 1→3 replicas at 70% CPU utilisation
- **NetworkPolicy** — only port 8080 inbound allowed
- **Vault sidecar** — secrets injected as files, zero secrets in Git

---

## Secrets Management

HashiCorp Vault injects secrets at pod startup via the Agent Injector sidecar pattern:
Pod starts → Vault sidecar authenticates via ServiceAccount JWT
→ Vault validates against Kubernetes auth method
→ Secrets written to /vault/secrets/config
→ App reads credentials from file (never env vars or manifests)

Zero secrets committed to Git at any point.

---

## Monitoring

kube-prometheus-stack provides:

- **Prometheus** — scrapes `/actuator/prometheus` every 15s
- **Grafana** — custom Spring Boot dashboard (HTTP rate, JVM heap, CPU, threads)
- **kube-state-metrics** — Kubernetes object state metrics
- **node-exporter** — hardware metrics per node

---

## Infrastructure Cost

| State | Daily cost |
|---|---|
| Active (8hrs, EKS running) | ~$1.50/day |
| Idle (EKS destroyed) | ~$0.00/day |

ECR, S3, DynamoDB stay within free tier. Jenkins runs on the Ubuntu laptop at zero cloud cost.

**Daily workflow:**
```bash
# Morning — bring up EKS
./infrastructure/scripts/morning.sh

# Evening — destroy to stop billing
./infrastructure/scripts/evening.sh
```

---

## Setup

### Prerequisites

- Ubuntu laptop with Jenkins, Docker, Minikube, Helm installed
- AWS account with credentials configured
- GitHub account

### One-time bootstrap

```bash
# 1. Create S3 state bucket and DynamoDB lock table
./infrastructure/bootstrap/init.sh

# 2. Apply persistent infrastructure (VPC, ECR, IAM)
cd infrastructure/terraform/persistent
terraform init && terraform apply

# 3. Configure the Jenkins laptop
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml

# 4. Add credentials to Jenkins
#    - aws-credentials (AWS access key + secret)
#    - github-token (GitHub personal access token)
```

### Daily usage

Push any change to `main` — the pipeline triggers automatically via GitHub webhook.

---

## Phases Completed

| Phase | Topic | Status |
|---|---|---|
| 1 | Terraform AWS Infrastructure | ✅ |
| 2 | Ansible Configuration Management | ✅ |
| 3 | Jenkins CI Pipeline + Dockerfile | ✅ |
| 4 | Helm Chart + ArgoCD GitOps | ✅ |
| 5 | Kubernetes Hardening | ✅ |
| 6 | HashiCorp Vault Secrets | ✅ |
| 7 | Prometheus + Grafana | ✅ |
| 8 | AWS EKS Production Cluster | ⏳ |

---

*Region: ap-south-1 (Mumbai) | Last updated: May 2026*
