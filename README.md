LearningSteps — DevOps Capstone
A production-grade DevOps pipeline for the LearningSteps FastAPI application. Automated deployment to Azure Kubernetes Service with security scanning, Infrastructure as Code, and full observability.
Live API: http://9.163.230.128/docs

Pipeline Overview
git push main
     │
     ▼
GitHub Actions
     │
     ├── Build Docker image (linux/amd64)
     │
     ├── Trivy scan ──── HIGH/CRITICAL found? ──► PIPELINE FAILS
     │
     ├── tfsec scan (Terraform security report)
     │
     ├── Push image → Azure Container Registry
     │
     └── Deploy → AKS (rolling update, zero downtime)
                       │
                       ▼
              http://9.163.230.128

Technology Stack
LayerTechnologyApplicationFastAPI (Python 3.13), PostgreSQLContainerizationDocker, Azure Container RegistryInfrastructureTerraform, Azure (AKS, PostgreSQL Flexible Server, VNET)CI/CDGitHub ActionsSecurityTrivy (image scanning), tfsec (IaC scanning)OrchestrationKubernetes (AKS) — namespace isolation, RBAC, health probes

Project Structure
learningsteps/
├── api/                        # FastAPI application
│   ├── main.py                 # App entry point + /health endpoint
│   ├── requirements.txt        # Python dependencies
│   ├── models/                 # Data models
│   ├── repositories/           # Database layer (PostgreSQL/asyncpg)
│   ├── routers/                # API routes
│   └── services/               # Business logic
│
├── infra-terraform/            # Infrastructure as Code
│   ├── versions.tf             # Provider versions
│   ├── variables.tf            # Input variables
│   ├── main.tf                 # Resource Group + ACR
│   ├── network.tf              # VNET + subnets
│   ├── database.tf             # PostgreSQL Flexible Server
│   ├── aks.tf                  # AKS cluster + AcrPull role
│   ├── backend.tf              # Remote state (Azure Storage)
│   └── outputs.tf              # AKS name, ACR server, DB host
│
├── k8s/                        # Kubernetes manifests
│   ├── namespace.yaml          # learningsteps namespace
│   ├── serviceaccount.yaml     # github-deployer RBAC
│   ├── configmap.yaml          # Non-sensitive config
│   ├── secret.yaml             # DATABASE_URL (gitignored)
│   ├── deployment.yaml         # 2 replicas, rolling update, probes
│   └── service.yaml            # LoadBalancer → public IP
│
├── .github/workflows/
│   └── pipeline.yml            # Build → Scan → Push → Deploy
│
├── Dockerfile                  # Non-root, linux/amd64
├── .dockerignore
└── README.md

Quick Start
Prerequisites

Azure CLI (az login)
Docker Desktop
Terraform
kubectl

1. Provision Infrastructure
bashcd infra-terraform

# Initialize with remote backend
terraform init

# Preview changes
terraform plan -var='db_password=YOUR_PASSWORD'

# Apply
terraform apply -var='db_password=YOUR_PASSWORD'
2. Configure GitHub Secrets
Add these in GitHub → Settings → Secrets → Actions:
SecretValueAZURE_CLIENT_IDService Principal app IDAZURE_CLIENT_SECRETService Principal passwordAZURE_TENANT_IDAzure tenant IDAZURE_SUBSCRIPTION_IDAzure subscription IDACR_LOGIN_SERVERlearningstepsacr.azurecr.ioDB_PASSWORDPostgreSQL admin password
3. Deploy to AKS
bash# Connect to AKS
az aks get-credentials \
  --resource-group learningsteps-rg \
  --name learningsteps-aks

# Apply manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/serviceaccount.yaml
kubectl apply -f k8s/configmap.yaml -n learningsteps
kubectl apply -f k8s/secret.yaml -n learningsteps
kubectl apply -f k8s/deployment.yaml -n learningsteps
kubectl apply -f k8s/service.yaml -n learningsteps

# Verify
kubectl get pods -n learningsteps
kubectl get service learningsteps-service -n learningsteps
4. Initialize Database
bashexport PGPASSWORD='YOUR_PASSWORD'
kubectl run psql-init --rm -it \
  --image=postgres:15 --restart=Never \
  --namespace=learningsteps \
  --env="PGPASSWORD=${PGPASSWORD}" \
  -- psql "host=learningsteps-db.postgres.database.azure.com dbname=learning_journal user=dbadmin sslmode=require" \
  -c "CREATE TABLE entries (id VARCHAR(36) PRIMARY KEY, data JSONB NOT NULL, created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW());"
5. Trigger Automated Deploy
bashgit push origin main
# Watch: https://github.com/orelsv/learningsteps/actions

API Endpoints
MethodEndpointDescriptionGET/healthHealth check (used by K8s probes)GET/docsSwagger UIGET/entriesGet all journal entriesPOST/entriesCreate a new entryGET/entries/{id}Get single entryPATCH/entries/{id}Update entryDELETE/entries/{id}Delete entry
Example:
bashcurl -X POST http://9.163.230.128/entries \
  -H "Content-Type: application/json" \
  -d '{
    "work": "Deployed LearningSteps to AKS",
    "struggle": "Terraform service CIDR conflict",
    "intention": "Add monitoring with Prometheus"
  }'

Infrastructure Recovery
The entire environment is reproducible from code:
bashcd infra-terraform

# Destroy everything
terraform destroy -var='db_password=YOUR_PASSWORD'

# Recreate everything
terraform apply -var='db_password=YOUR_PASSWORD'
After recovery, re-run steps 3 and 4 above.

Security

Image scanning: Trivy blocks deployment on HIGH/CRITICAL CVEs
IaC scanning: tfsec reports Terraform misconfigurations
Non-root container: App runs as appuser (UID 1000)
Namespace isolation: Dedicated learningsteps namespace
RBAC: github-deployer ServiceAccount with minimal permissions
Private database: PostgreSQL accessible only via VNET, no public access
Secret management: Credentials in Kubernetes Secrets, never in code


Troubleshooting
Pods not starting (ErrImagePull)
bash# Check AcrPull permission
az role assignment create \
  --assignee $(az aks show -g learningsteps-rg -n learningsteps-aks \
    --query "identityProfile.kubeletidentity.objectId" -o tsv) \
  --role AcrPull \
  --scope $(az acr show --name learningstepsacr --query "id" -o tsv)
Platform mismatch (Mac M-series)
bashdocker build --platform linux/amd64 -t learningstepsacr.azurecr.io/learningsteps-api:latest .
Database connection error
bashkubectl logs -l app=learningsteps-api -n learningsteps --tail=20
kubectl describe secret learningsteps-secrets -n learningsteps
AKS stopped (cost saving)
bashaz aks start --resource-group learningsteps-rg --name learningsteps-aks

Cleanup
bash# Delete Kubernetes resources
kubectl delete namespace learningsteps

# Destroy infrastructure
cd infra-terraform
terraform destroy -var='db_password=YOUR_PASSWORD'