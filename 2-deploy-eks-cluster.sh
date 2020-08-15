#!/usr/bin/env bash

working_dir=`pwd`

echo ""

echo "Checking if prerequisites are met ..."

if ! hash terraform 2>/dev/null
then
    echo "'terraform' was not found in PATH"
    echo "Kindly ensure that you have terraform installed"
    echo "Please refer to README"
    exit
fi

if ! hash aws 2>/dev/null
then
    echo "'aws cli' was not found in PATH"
    echo "Kindly ensure that you have aws-iam-authenticator installed"
    echo "Please refer to README"
    exit
fi

if ! hash aws-iam-authenticator 2>/dev/null
then
    echo "'aws-iam-authenticator' was not found in PATH"
    echo "Kindly ensure that you have aws-iam-authenticator installed"
    echo "Please refer to README"
    exit
fi

FILE=~/.terraform.d/plugins/terraform-provider-kubectl
if [ ! -f "$FILE" ];
then
    echo "$FILE does not exist"
    echo "Please refer to README"
    exit
fi



echo "Please enter the name of the new cluster, this will be used to create the cluster module folder:"
echo "It is recommended to use <project or customer>-<stage>-eks-spot as a convention for the cluster name, e.g. my-business-unit-dev-qa-eks-spot"
echo "The cluster name should be unique, since we use the cluster name as the S3 bucket name!"
echo "Please enter the name of the new ✅ cluster name ✅:"
read cluster_name
echo "Please provide the ✅ region ✅, e.g. us-east-1, us-east-2, eu-central-1, ca-central-1, etc.."
read region
echo

export AWS_DEFAULT_REGION=$region

echo ""
echo "The current list of EKS clusters:"

printf " ✅ \n"
aws eks list-clusters > eks-clusters
cat eks-clusters
printf " ✅ \n"

echo

echo
echo "cloning the base cluster module to: $cluster_name folder"
echo

cp -r base $cluster_name

printf "   Setting the CLUSTER_NAME in cluster.tfvars …\n"
echo
cp ./$cluster_name/cluster.tfvars.tmpl ./$cluster_name/cluster.tfvars
cluster_tfvars="./$cluster_name/cluster.tfvars"
backend="./$cluster_name/backend.tf"
readme="./$cluster_name/README.md"
asg_name="cluster-autoscaler-asg-name.yml"
echo
echo "Substituting values in cluster.tfvars, s3 backend.tf and README.md files:"

sed -i -e "s@{{CLUSTER_NAME}}@${cluster_name}@g" "${cluster_tfvars}"
sed -i -e "s@{{REGION}}@${region}@g" "${cluster_tfvars}"
sed -i -e "s@{{CLUSTER_NAME}}@${cluster_name}@g" "${backend}"
sed -i -e "s@{{REGION}}@${region}@g" "${backend}"
sed -i -e "s@{{CLUSTER_NAME}}@${cluster_name}@g" "${readme}"
sed -i -e "s@{{REGION}}@${region}@g" "${readme}"

printf " Done ✅ \n"

echo "##############################################################################################################################################"
echo "Did you already run the ./1-clone-base-module.sh script and went through the installation steps in the README file to deploy the EKS cluster?"
echo "If yes, you can go ahead and continute here"
echo "Now we're going to create the ✅ $cluster_name ✅ by running "make apply" from the $cluster_name folder"
echo "We create a bucket named ✅ $cluster_name ✅ "
echo "We place the ssh private key named $cluster_name-key under the $cluster_name folder"
echo ""
echo "##############################################################################################################################################"

function ask_yes_or_no() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

if [[ "no" == $(ask_yes_or_no "Are you sure you wish to continue?") || \
      "no" == $(ask_yes_or_no "Would you like to have a cup of coffee, tee or a cold German Bier? ;-)") ]]
then
    echo "Okay, skipped!"
    echo "You can might want to delete the cluster module folder or follow the README in the cluster folder and go though the installation steps manually"
    exit 0
fi

aws ec2 create-key-pair --key-name $cluster_name-key --query 'KeyMaterial' --output text > ./$cluster_name/$cluster_name-key.pem

if [[ $AWS_DEFAULT_REGION == 'us-east-1' ]]
then
aws s3api create-bucket --bucket $cluster_name --acl private --region $region >> ./$cluster_name/s3_bucket
else
aws s3api create-bucket --bucket $cluster_name --acl private --region $region --create-bucket-configuration LocationConstraint=$region >> ./$cluster_name/s3_bucket
fi

aws s3api put-public-access-block --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" --bucket $cluster_name &>/dev/null
cat ./$cluster_name/s3_bucket
sleep 5
cd $cluster_name
export CLUSTER_NAME=$cluster_name
make plan
make apply 

echo "############################################################################################################################################"
echo "If you abort the cluster creation or destroy the cluster, please make sure to clean-up and delete the key and the s3 bucket with:"
# echo "aws s3api delete-bucket --bucket $cluster_name"
echo "aws s3 rb s3://$cluster_name --force"
echo "export AWS_DEFAULT_REGION=$region"
echo "aws ec2 delete-key-pair --key-name $cluster_name-key &>/dev/null"
echo "Now exporting KUBECONFIG and listing the nodes and the clusters:"
export KUBECONFIG=./kubeconfig_$cluster_name
sleep 5
kubectl get nodes -o wide
aws eks list-clusters > eks-clusters
cat eks-clusters
rm eks-clusters
echo "✅ Are you happy? ;-)  \n"
echo "If you don't need the cluster, please run "make destroy" from the cluster folder"
echo "If you want to keep the cluster, add the cluster folder to the git repo"
echo "To deploy the cluster-autoscaler please refer to Step 4 in the README of the cluster folder"
echo "We try to deploy the metrics server form the addons"
kubectl apply -f ../addons/metrics-server-0.3.6/deploy/1.8+/
kubectl rollout status deployment metrics-server -n kube-system
export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --output table | grep arash-docker-eks | grep "AutoScalingGroupName" | awk '{ print $4 }')
sed -i -e "s@{{ASG_NAME}}@${ASG_NAME}@g" "${asg_name}"
kubectl create -f cluster-autoscaler-asg-name.yml
echo "if you get something like this about the rollout status of the metrics server:"
echo "deployment "metrics-server" successfully rolled out"
echo "✅ You'll feel hopefully happy with Kubernauts' Terraform EKS implementation :-)"
echo "############################################################################################################################################"


