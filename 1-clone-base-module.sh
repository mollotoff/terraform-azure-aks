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

echo

echo "Please enter the name of the new cluster, this will be used to create the cluster module folder:"
echo "It is recommended to use <project or customer>-<stage>-eks-spot as a convention for the cluster name, e.g. my-business-unit-dev-qa-eks-spot"
echo "The cluster name should be unique, since we use the cluster name as the S3 bucket name!"
echo "Please enter the name of the new cluster name:"
read cluster_name
echo "Please provide the region, e.g. us-east-1, us-east-2, eu-central-1, ca-central-1, etc.."
read region
echo

export AWS_DEFAULT_REGION=$region

echo ""
echo "The current list of EKS clusters:"

printf " ✅ \n"
aws eks list-clusters
printf " ✅ \n"

echo

echo
echo "cloning the base cluster module to: $cluster_name folder"
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
echo
echo "Substituting values in cluster.tfvars, s3 backend.tf and README.md files:"

sed -i -e "s@{{CLUSTER_NAME}}@${cluster_name}@g" "${cluster_tfvars}"
sed -i -e "s@{{REGION}}@${region}@g" "${cluster_tfvars}"
sed -i -e "s@{{CLUSTER_NAME}}@${cluster_name}@g" "${backend}"
sed -i -e "s@{{REGION}}@${region}@g" "${backend}"
sed -i -e "s@{{CLUSTER_NAME}}@${cluster_name}@g" "${readme}"
sed -i -e "s@{{REGION}}@${region}@g" "${readme}"

printf " Done ✅ \n"

echo "############################################################################################################################################"
echo ""
echo "Please refer to the README file under the ✅ $cluster_name ✅ module folder and go through the Step 1-3 to deploy the EKS cluster :-)"
echo "AND make sure to create a new key in AWS console named $cluster_name-key and think about where to store the key :-)"
echo ""
echo "############################################################################################################################################"




