<p align="center">
<img src="https://github.com/kura-labs-org/kuralabs_deployment_1/blob/main/Kuralogo.png">
</p>
<h1 align="center">C4_deployment-9<h1> 

# Planning:

## Diagram:

![Deployment9 1 drawio (1)](https://github.com/Jmo-101/Eks_ecommerce_app/assets/128739962/87210d56-b1b9-4242-9e97-e9c78283bdfc)

# Steps
### Terraform (Sameen)
Terraform is a tool that helps you create and manage your infrastructure. It allows you to define the desired state of your infrastructure in a configuration file, and then Terraform takes care of provisioning and managing the resources to match that configuration. This makes it easier to automate and scale your infrastructure and ensures that it remains consistent and predictable.

### Jenkins Agent Infrastructure (Sameen)
Use Terraform to spin up the Jenkins Agent Infrastructure and to include the installs needed for the Jenkins manager instance, the install needed for the Jenkins Docker agent instance, and the install needed for the Jenkins Kubernetes agent instance.

Terraform was also utilized to launch a separate infrastructure Kubernetes infrastructure (main infrastructure). The infrastructure consisted of a VPC, 2 public subnets, and 2 private subnets each within their own availability zone (us-east-1a and us-east-1b). An internet gateway as well as a NAT gateway were also configured. 

Preparing the Jenkins Kubernetes agent instance 
The user data script which ran upon initialization of the instance was responsible for installing EKS, Kubectl, AWSCLI, and the default-jre dependency. 

This instance was utilized in manually installing the cluster. To create the cluster the following command was used:

``  eksctl create cluster cluster01  --vpc-private-subnets="your-subnets"  --vpc-public-subnets="your-subnets"--without-nodegroup
``
“Your-subnets” was replaced with the subnet id of the respective private and public subnets from the main infrastructure and are separated by commas. 

After the cluster was successfully created, the following command was run to create two t2.medium nodes.

``eksctl create nodegroup --cluster cluster02 --node-private-networking --node-type t2.medium --nodes 2``

### Configuring ALB Controller
The ALB controller is configured within the Jenkins Kubernetes agent instance. 

1. In order to configure the ALB Controller,  it is necessary to first add OpenID connect to the cluster. Enter this command to add OpenID to the cluster: 
``eksctl utils associate-iam-oidc-provider --cluster cluster04 --approve``

Then to make sure that the OpenID is connected to the cluster, run the following command:

``aws iam list-open-id-connect-providers``

2. Next step is to navigate to AWS website, under the VPC tab, select subnets. Add an additional tag to the subnets utilized in the main infrastructure. The key will be “kubernetes.io/role/elb” and the value will be “1” 

3. Next download the IAM policy with the following command below:

`` wget https://raw.githubusercontent.com/kura-labs-org/Template/main/iam_policy.json ``

The iam_policy.json will be downloaded 

4. Next, create the AWS policy with the following command. Once it is created the output of the created policy will display the ARN. Copy and paste that ARN as it will be used in a future command. If the policy already exists, navigate to AWS and under the IAM roles tab, search for the existing policy called “AWSLoadBalancerControllerIAMPolicy”. Copy and paste the ARN associated with the policy.

5. Next create the service account. Be sure to add the name of your cluster and attach-policy-arn values copied in the previous step:

``` eksctl create iamserviceaccount \
--cluster=cluster04 \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::266686430719:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--approve
```

6. Next create certificate manager for the ingress controller with the following command:

```
kubectl apply \
--validate=false \
-f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
```

7. In this step, the load balancer controller is created by downloading and running the following commands:

``wget https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.5/v2_4_5_full.yaml``

This command downloaded a file called “v2_4_5_full.yaml”. Within this file replace {cluster-name=your-cluster-name} with the cluster name on line 731. 

After the changes to the file have been made, run the following command to apply the file. 

``kubectl apply -f v2_4_5_full.yaml``

After this, the following command can be utilized to view the controller:

``kubectl get deployment -n kube-system aws-load-balancer-controller``

<img width="1388" alt="PROBLEMS OUTPUT" src="https://github.com/Jmo-101/Eks_ecommerce_app/assets/128739962/7b31f1ff-1bd1-4e28-9c8d-3a9929532151">

8. Last step is to run the following command:

``kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds”``

After this the ingressClass.yml can be ran 

### Install Cloudwatch Agent on AWS EKS

1. To install the Amazon EKS cloud watch agent add-on, first add the CloudWatchAgentServerPolicy to your worker nodes. Run the following command to do so:

```
aws iam attach-role-policy \
--role-name my-worker-node-role \
--policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

“My-worker-node-role” must be replaced with the IAM role used by the Kubernetes worker nodes which can be found on AWS.

2. Last step is to enter the following command to install the add-on:

``aws eks create-addon --cluster-name my-cluster-name --addon-name amazon-cloudwatch-observability``

# Group Members & Roles:

Annie Lam - Data Ops engineer
Kevin Edmond - System administrator
Sameen Khan - Chief Architect
Jorge Molina - Project Manager
