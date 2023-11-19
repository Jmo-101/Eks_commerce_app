<p align="center">
<img src="https://github.com/kura-labs-org/kuralabs_deployment_1/blob/main/Kuralogo.png">
</p>
<h1 align="center">Eks_Ecommerce_app<h1> 

# Planning:
<img width="749" alt="Screenshot 2023-11-18 at 9 37 21 PM" src="https://github.com/Jmo-101/Eks_ecommerce_app/assets/138607757/a5191779-28dc-47ca-9c7e-0aa81334d065">


# Group Members & Roles:

- Annie Lam - Data Ops engineer
- Kevin Edmond - System administrator
- Sameen Khan - Chief Architect
- Jorge Molina - Project Manager

# Purpose:

The purpose of this deployment was to be able to successfully deploy an e-commerce application using Kubernetes. In order to achieve this, we used tools such as Terraform, Jenkins, Docker, and AWS EKS.

# Steps
### Terraform (Sameen)
Terraform is a tool that helps you create and manage your infrastructure. It allows you to define the desired state of your infrastructure in a configuration file, and then Terraform takes care of provisioning and managing the resources to match that configuration. This makes it easier to automate and scale your infrastructure and ensures that it remains consistent and predictable.

### Jenkins Agent Infrastructure (Sameen)
Use Terraform to spin up the Jenkins Agent Infrastructure and to include the installs needed for the Jenkins manager instance, the install needed for the Jenkins Docker agent instance, and the install needed for the Jenkins Kubernetes agent instance.

Terraform was also utilized to launch a separate infrastructure Kubernetes infrastructure (main infrastructure). The infrastructure consisted of a VPC, 2 public subnets, and 2 private subnets each within their own availability zone (us-east-1a and us-east-1b). An internet gateway as well as a NAT gateway were also configured. 

Preparing the Jenkins Kubernetes agent instance 
The user data script which ran upon initialization of the instance was responsible for installing EKS, Kubectl, AWSCLI, and the default-jre dependency. 

This instance was utilized in manually installing the cluster. To create the cluster the following command was used:

``eksctl create cluster cluster01  --vpc-private-subnets="your-subnets"  --vpc-public-subnets="your-subnets"--without-nodegroup``

“Your-subnets” was replaced with the subnet id of the respective private and public subnets from the main infrastructure and are separated by commas. 

After the cluster was successfully created, the following command was run to create two t2.medium nodes.

``eksctl create nodegroup --cluster cluster02 --node-private-networking --node-type t2.medium --nodes 2``


# DockerFiles:

To begin we need to build our Docker container images using the Dockerfiles stored in our repo. The first stage of the pipeline clones our Github repo to gather the source files needed for deployment. The Jenkins pipeline stage `Build` performs a docker build using the docker files, dockerfile.be and dockerfile.fe. These represent how our backend and frontend container images should be built. The `docker build` is run using the `-f` option to specify the dockerfile and the `-t` option to tag the images with a specific name. Next, we proceed to the `Login` pipeline stage to connect to our Docker Hub repository using stored credentials in the Jenkins management console. Now, in pipeline stage `Push`, we’re ready to use our Docker hub connection to push our newly created or updated docker images. Once pushed, the container images are ready to be consumed by our Kubernetes cluster.

# EKS:

In order to manage our application containers we are going to implement Kubernetes, a container orchestration platform. For our deployment, we’ll be using AWS EKS, a managed Kubernetes service with AWS. Our EKS cluster and infrastructure has already been deployed by our Chief Architect using. To deploy our application into the Kubernetes cluster we have set up several pipeline stages to apply our Kubernetes yaml files to the environment. The pipeline steps are:

- `Backend App Deployment : deployment_be.yaml`: This file creates the backend application container.
- `Frontend App Deployment`: This file creates the frontend application container.
- `Deploy App Services`: This file creates a `Cluster IP` for internal connections to the backend container and a `NodePort` service for connections to our frontend containers.  
- `Deploy Ingress`: This file creates an ingress resource that allows external HTTP traffic to reach our frontend `NodePort` server via `Application Load Balancer`.

When the pipeline completes, an Application Load Balancer becomes available supplying us with a DNS address to allow user interaction with our application.

DNS: `http://k8s-default-ecommerc-8a588012f9-709041982.us-east-1.elb.amazonaws.com/`
<br>
![frontend_app2](images/frontend_app2.png)<br>
![frontend_app](images/frontend_app.png)<br>


# CloudWatch Agent:

# Issues:

`Error - "Request failed with status code 500"`: After deploying the application successfully the first time, we encountered this error on the homepage. Initially, the error was thought to be a permissions error since the frontend containers logs showed some scp permissions errors. However, the scp policies govern our AWS accounts within an AWS Organization; our account should have adequate permissions for resources.

`Solution`: Upon further review of the frontend application’s package.json file I noticed that the application is attempting to connect to `http://backservice:8000`. I had to modify the service.yaml file’s `backendservice` name to reflect `backservice`.
<br>
![request_failed_500](images/request_failed_500.png)<br>



# Optimization:

Our current setup for the backend application container is not optimized for a seamless and user-friendly interaction. Deploying more than one backend container would cause our user data to become out of sync with each container hosting its own database store. Moreover, lost data is an issue if the container is terminated due to its ephemeral storage use. These issues can be resolved by configuring some or all worker nodes to use persistent volumes. With persistent volumes the participating nodes can make data housed in a central data store available to running containers. Containers can connect to these persistent volumes using a persistent volume claim (PVC). PVC’s setup the request for persistent volume storage access using various configurations. Containers requiring persistent storage can be managed using stateful sets rather than a deployment which can manage the create and delete process for PVCs for its workload.
