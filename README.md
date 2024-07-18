# Conjur Cloud K8s Secrets Accelerator
A sandbox for exploring Conjur Cloud integration with Kubernetes
## Overview
This Accelerator demonstrates 8 different ways a pod running in Kubernetes can access secrets from Conjur Cloud. All use-cases are built and tested to work with Conjur Cloud from either MacOs or Ubuntu 24.04 hosts. All use-cases access Conjur Cloud, but have also been tested and work with a Conjur Cloud Edge node. All use-cases *should* work with Conjur Enterprise, but that has been neither implemented nor tested.
<br>
## Requirements
 - Demo host:
   - Mac:
     - Arm/Intel CPU
     - Docker Desktop w/ Kubernetes enabled
   - Linux VM:
     - Ubuntu 24.04
     - x86_64/amd64 (Intel) CPU
     - 8GB RAM
     - 32GB disk
 - Network:
   - Outbound IPV4 network access to CyberArk shared-services tenant
   - No inbound port access required
 - CyberArk shared-services tenant:
   - CyberArk Identity
   - Privilege cloud
   - Conjur Cloud 
 - CyberArk admin service user
   - Oauth confidential client
   - Roles:
     - Privilege Cloud Administrators
     - Secrets Manager - Conjur Cloud Admin

## Setup
### Prerequisites:
1. Clone or copy this repo into demo host.
2. cd to:
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.../Accelerator-K8sSecrets<br>
and edit demo-vars.sh to change the CYBERARK_SUBDOMAIN_NAME value to match your tenant subdomain name.
   - NOTE: While other variables in demo-vars.sh can be changed, it is HIGHLY recommended to use the defaults unless there is a name collision or other compelling reason not to do so.
3. Source demo-vars.sh and, when prompted, provide the service user username and password.
   - NOTE: The username and password are stored as environment variables. THIS IS A PRIVILEGED ADMIN USER IN YOUR TENANT. Be sure to exit the shell once your session is complete to avoid compromising the service user credentials.
4. cd to:<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.../Accelerator-K8sSecrets/1-admin-role/0-prereqs/<br>
5. Installation<br>
   - MacOs:
     - Run:<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;./1-setup-mac.sh<br>
to verify Docker/K8s is functioning & install Helm if needed.
   - Ubuntu:<br>
     - Run:<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;./1-setup-ubuntu.sh<br>
  to install Docker, kubectl, Minikube, and Helm.<br>
     - Exit and login again in order to run Docker without sudo.<br>
     - Run:<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;kubectl get pods --all-namespaces<br>
   to ensure K8s is functioning.


### **Administrator Role**
The Administrator executes tasks that are less frequently performed and require elevated privileges to create foundational resources required by workloads. These include:
- CyberArk safe administration in Privilege Cloud
- Conjur authenticator endpoints and workload base policies
- K8s resources shared across namespaces

To perform these tasks:
1. cd to:
  <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.../Accelerator-K8sSecrets/1-admin-role/1-setup/<br>
  Run:
   <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;./1-admin-setup.sh<br>
   This script:
    - Sets up the cluster authentication endpoint
      - See: [Configure the JWT Authenticator](https://docs.cyberark.com/conjur-cloud/latest/en/Content/Integrations/k8s-ocp/k8s-jwt-authn.htm?tocpath=Authenticate%20workloads%7CSecure%20Kubernetes%7C_____2#ConfiguretheJWTAuthenticator)
    - Sets up the cluster workload policy
    - Creates a golden configmap for connection to Conjur Cloud
      - See: [Prepare the Kubernetes cluster and Golden ConfigMap](https://docs.cyberark.com/conjur-cloud/latest/en/Content/Integrations/k8s-ocp/k8s-jwt-set-up-apps.htm#PreparetheKubernetesclusterandGoldenConfigMap)
    - Creates a safe and MySQL database account in Privilege Cloud
2. cd to:
  <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.../Accelerator-K8sSecrets/1-admin-role/2-mysql/<br>
   Run:
   <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;./1-deploy-mysql.sh<br>
   This script:
   - Starts a MySQL server container in K8s.
   - Loads a database named 'petclinic'
   - Tests a simple query against the 'pets' table.

### **Application Owner Role**
The Application Owner executes tasks that are more frequently performed and do not require elevated privileges. They are done on behalf of a project or set of workloads and include:
- Workload builds
- CyberArk account administration in Privilege Cloud
- Conjur policy administration - workload identity creation and role grants
- K8s namespace administration - configmap and service account creation<br>

To perform these tasks:

1. cd to:
  <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.../Accelerator-K8sSecrets/2-app-owner-role/0-app-build/<br>
   Run:
   <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;./build.sh<br>
   This script builds the pod container used for all use-cases. It contains three scripts that demonstrate how to access secrets:
   - mysql_REST.sh - connects to the MySQL database using secrets retrieved with the Conjur REST API
   - mysql_k8s_secrets.sh - connects to the MySQL database using Kubernetes secrets.
   - mysql_file.sh - connects to the MySQL database using secrets from a JSON file.
2. cd to:
    <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.../Accelerator-K8sSecrets/2-app-owner-role/1-setup/<br>
   Run:
   <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;./1-app-owner-setup.sh<br>
   This script:
    - Sets up the workload namespace in K8s.
    - Creates the workload service account in the namespace.
    - Copies the Conjur golden configmap in to the namespace.
    - Creates a workload identity in Conjur Cloud that:
      - corresponds to the workload namespace and service account
      - has permission to authenticate to the cluster authn-jwt endpoint in Conjur Cloud
      - has permission to retrieve the MySQL account values from Conjur Cloud.

### This completes all setup tasks.
<hr>

## Use-Case Exploration
To explore the ways of providing secrets to K8s workloads:<br>
1. cd to:<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.../Accelerator-K8sSecrets/2-app-owner-role/2-use-cases/
2. Run:<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ls<br>
to get a listing of the use-case directories. You can cd into each and run the scripts in the prescribed order to exercise each of the methods of secrets delivery.<br>

Regardless of use-case, they all have the following in common:
- The MySQL database access values are centrally managed in the Privilege Cloud K8s-MySQL account and synced to Conjur.
- Secrets providers authenticate to Conjur using the K8s service account and corresponding Conjur workload identity.
- Secrets providers retrieve K8s-MySQL account values from Conjur and provide them to workloads.
- Workloads use the retrieved values to access the MySQL Petclinic database.


| Use-Case Directory | Secrets Access Method | Secrets Provider                    |
|--------------------|-----------------------|-------------------------------------|
| csi-driver         | tmpfs volume          | [Container Storage Interface Driver](https://docs.cyberark.com/conjur-enterprise/13.2/en/Content/Integrations/k8s-ocp/k8s-jwt-secrets-store-csi-driver.htm)
| ext-secrets-opr8r  | Kubernetes Secrets    | [External Secrets Operator](https://external-secrets.io/latest/provider/conjur/)
| k8sfile-init       | JSON/YAML File        | [Conjur Kubernetes Secrets Provider](https://docs.cyberark.com/conjur-cloud/latest/en/Content/Integrations/k8s-ocp/cjr-k8s-jwt-sp-lp.htm)
| k8sfile-sidecar    | JSON/YAML File        | [Conjur Kubernetes Secrets Provider](https://docs.cyberark.com/conjur-cloud/latest/en/Content/Integrations/k8s-ocp/cjr-k8s-jwt-sp-lp.htm)
| k8ssecret-init     | Kubernetes Secrets    | [Conjur Kubernetes Secrets Provider](https://docs.cyberark.com/conjur-cloud/latest/en/Content/Integrations/k8s-ocp/cjr-k8s-jwt-sp-lp.htm)
| k8ssecret-job      | Kubernetes Secrets    | [Conjur Kubernetes Secrets Provider](https://docs.cyberark.com/conjur-cloud/latest/en/Content/Integrations/k8s-ocp/cjr-k8s-jwt-sp-lp.htm)
| k8ssecret-sidecar  | Kubernetes Secrets    | [Conjur Kubernetes Secrets Provider](https://docs.cyberark.com/conjur-cloud/latest/en/Content/Integrations/k8s-ocp/cjr-k8s-jwt-sp-lp.htm)
| rest-api           | application variables | [Conjur REST API ](https://docs.cyberark.com/conjur-cloud/latest/en/Content/Developer/lp_REST_API.htm?tocpath=Developer%20reference%7CConjur%20Cloud%20REST%20APIs%7CREST%C2%A0APIs%7C_____0)

### When to use which?
Multiple options can be confusing. Here are some guidelines to help choose the solution that best fits your needs.

1. Which solution depends on how the workload does/should consume secrets.
   - **K8s secrets:** This is the most 'natural' method for K8s workloads to access secrets.
   - **File:** Often the easiest choice for apps built for other environments that have been lifted & shifted to K8s, e.g. secrets in Spring boot properties, Ansible values, config files, etc.
   - **Direct API access:** Puts the onus of work on the application coder but has the least runtime overhead.
2. External Secrets Operator (ESO) or CSI driver?
   - We recommend using the ESO unless there's a compelling reason to use the CSI driver. The ESO is purpose-built for K8s secrets whereas the CSI leverages a storage solution to push secrets into volumes.
3. The Conjur Kubernetes Secrets Provider container mode choice depends on how long the workload typically runs, and if memory resources are a concern.
   - **Init container:**
     - Advantages:
       - Retrieves secrets then exits, freeing memory.
     - Disadvantages:
       - Unable to update secrets if they change.
       - Not ideal for long running workloads.
   - **Sidecar:**
     - Advantages:
       - Stays running, can update secrets.
       - Good for long running workloads.
     - Disadvantages:
       - Consumes memory per pod.
       - Pods must be restarted for workloads to see changed secrets, typically with a [rolling update](https://www.google.com/search?q=kubernetes+secrets+rolling+upgrade).
   - **Application:**
     - Advantages:
       - Can update secrets.
       - Can run intermittently as a job, reducing memory consumption vs. sidecar.
       - Simplified workload deployment manifests.
     - Disadvantages:
       - Must be scheduled separately from workload deployments.
       - Pods must be restarted for workloads to see changed secrets, typically with a [rolling update](https://www.google.com/search?q=kubernetes+secrets+rolling+upgrade).
   
## Conjur Policy Model
The authn-jwt endpoint id is named for the execution environment hosting its JWKS endpoint. In this case that is the K8s cluster, but in other cases it could be a Jenkins controller, Gitlab tenant or other JWT provider. In general there should be one authn-jwt endpoint per JWT provider. Because the identity-path variable is one-to-one for each authn-jwt endpoint, ALL workloads authenticating to that endpoint must be created at the endpoint's identity-path. In this implementation, the identity-path is `data/k8s-cluster`.
<br>
```
  conjur/authn-jwt/k8s-cluster/group:apps(authenticate)
  |
  v
  data/k8s-cluster/group:workloads
  |
  |  data/vault/K8sXlr8r/delegation/group:consumers(read_secrets)
  |  |
  v  v
  data/k8s-cluster/host:<app-namespace>:<jwt-service-account>
```
The workload identity in K8s is the service account. The workload identity (AKA `host`) in Conjur is named for the K8s service account. Conjur role grants give the workload:
- authentication permission via the cluster workloads group, and
- secrets access permission via the CyberArk safe consumers group.

The rationale for the ostensibly redundant `data/k8s-cluster/workloads` group is so the App Owner role does not need access to the `conjur/authn-jwt` policy branch, which is managed by the Administrator role. For simplicity, this implementation uses a single, all-powerful administrator identity. But in a fully realized implementation, workload identity administration would be automated with a Conjur workload identity that has access only to the `data/k8s-cluster` policy branch. This would adhere to the principle of least-privilege.