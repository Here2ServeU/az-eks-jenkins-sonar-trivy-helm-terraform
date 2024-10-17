#### Tools to Install:

	•	Azure CLI: To install and configure Azure CLI, go to https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
	•	AKS (Azure Kubernetes Service): No specific tool needed, but you’ll be working with az commands to manage AKS.
	•	KUBECTL: To install KUBECTL, go to https://kubernetes.io/docs/tasks/tools/
	•	HELM: To install Helm, go to https://helm.sh/docs/intro/install/

#### Prerequisites
**Install Azure CLI**
* curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

### Step 1: Create AKS Cluster
**Use Terraform configuration files to create the AKS cluster.**
* cd aks-cluster
* Change variables in the terraform.tfvars file

**Run the following terraform commands**
* terraform init 
* terraform plan 
* terraform apply

#### Step 2: Update kubeconfig
* az aks get-credentials --resource-group $(terraform output -raw t2s_services_resource_group) --name $(terraform output -raw t2s_services_cluster_name)

#### Step 3: Create Namespace and name it jenkins
* kubectl get ns             # To verify
* kubectl create ns jenkins  # To create a namespace

#### Step 4: Installing Helm on Local Machine
* brew install helm   # This is when using macOS. Use the official Helm Documentation in case you use a different OS. 
* helm version

#### Step 5: Install and Configure Jenkins for CI/CD
* helm repo add jenkins https://charts.jenkins.io
* helm repo update
* helm install jenkins jenkins/jenkins --set controller.serviceType=LoadBalancer
* kubectl cluster-info  # To view the Cluster info
* kubectl get nodes  # To verify the Worker Nodes

#### Step 6: Access Jenkins UI
**Get the Jenkins admin password**
* kubectl exec --namespace default -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo

**Get the Load Balancer URL for Jenkins**
* kubectl get svc --namespace default -w jenkins

***The output will be something like this:
* a8cc903b184cb4e908a01a07f7748594-416424995.azure.com.
* Paste it on the browser: a8cc903b184cb4e908a01a07f7748594-416424995.azure.com:8080.
* For Username: Admin; For Password: Use the command above to retrieve the password

#### Step 7: Install Plugins
***Docker Pipeline
GitHub Plugin
Kubernetes Plugin
Azure Credentials Plugin
Pipeline Plugin
GitLab Credentials
SonarQube
Trivy***

#### Step 8: Configure the Plugins
**Dashboard => Manage Jenkins => Tools**

**Set up Jenkins Pipeline**
***Create a file and name it Jenkinsfile***

#### Step 9: Taint each node

**Taint nodes for SonarQube**
* kubectl taint nodes <node-name-1> tool=sonarqube:NoSchedule

**Taint nodes for Trivy**
* kubectl taint nodes <node-name-2> tool=trivy:NoSchedule

**Taint nodes for Grafana**
* kubectl taint nodes <node-name-2> tool=grafana:NoSchedule

**Taint nodes for Prometheus**
* kubectl taint nodes <node-name-2> tool=prometheus:NoSchedule

#### Step 10: Install SonarQube with Helm and on Its Dedicated Node
* helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
* helm repo update
* helm install sonarqube sonarqube/sonarqube \
    --namespace sonarqube \
    --create-namespace \
    --set nodeSelector.tool=sonarqube \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=sonarqube \
    --set tolerations[0].effect=NoSchedule \
    --set persistence.storageClass="default" \
    --set service.type=LoadBalancer

#### Step 11: Install Trivy with Helm and on Its Dedicated Node
* helm repo add aqua https://aquasecurity.github.io/helm-charts
* helm repo update
* helm install trivy aqua/trivy-operator \
    --namespace trivy-system \
    --create-namespace \
    --set nodeSelector.tool=trivy \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=trivy \
    --set tolerations[0].effect=NoSchedule

#### Step 12: Install Prometheus with Helm and on Its Dedicated Node
* helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
* helm repo update
* helm install prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --create-namespace \
    --set nodeSelector.tool=prometheus \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=prometheus \
    --set tolerations[0].effect=NoSchedule

#### Step 13: Install Grafana with Helm and on Its Dedicated Node
* helm repo add grafana https://grafana.github.io/helm-charts
* helm repo update
* helm install grafana grafana/grafana \
    --namespace monitoring \
    --set nodeSelector.tool=grafana \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=grafana \
    --set tolerations[0].effect=NoSchedule \
    --set persistence.storageClass="default" \
    --set service.type=LoadBalancer

#### Step 14: Verify Deployments
* kubectl get pods -o wide -n sonarqube
* kubectl get pods -o wide -n trivy-system
* kubectl get pods -o wide -n monitoring

#### Step 15: Access the Tools
**These commands will provide the external IP addresses of SonarQube, Trivy, Prometheus, and Grafana.**
* kubectl get svc -n sonarqube
* kubectl get svc -n trivy-system
* kubectl get svc -n monitoring

#### Step 16: Create and Deploy a Website
* mkdir t2s-website
* cd t2s-website
* touch Dockerfile

***Add the following content to the Dockerfile***
FROM nginx:alpine

RUN echo '<html><body><h1>Hello from T2S. Congratulations for having set up a complete infrastructure that is scalable, highly available, resilient, accessible, and cost-efficient. Great job!</h1></body></html>' > /usr/share/nginx/html/index.html

* docker build -t t2s-website .
* docker tag t2s-website <your-repo>/t2s-website:latest
* docker push <your-repo>/t2s-website:latest

#### Step 17: Create Kubernetes Deployment and Service
* touch website-deployment.yaml

***Add this content to the deployment file***

apiVersion: apps/v1
kind: Deployment
metadata:
  name: t2s-website
  labels:
    app: t2s-website
spec:
  replicas: 1
  selector:
    matchLabels:
      app: t2s-website
  template:
    metadata:
      labels:
        app: t2s-website
    spec:
      containers:
      - name: t2s-website
        image: <your-repo>/t2s-website:latest  # Replace with your Docker image repo
        ports:
        - containerPort: 80

* touch website-service.yaml
***Add this content to the service file***

apiVersion: v1
kind: Service
metadata:
  name: t2s-website-service
spec:
  type: LoadBalancer
  selector:
    app: t2s-website
 
