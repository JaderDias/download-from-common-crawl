#!/bin/bash
environment="$1"
if [ -z "$environment" ]
then
    echo "Usage: deploy.sh <environment>"
    exit 1
fi

echo -e "\n+++++ Starting deployment +++++\n"

rm -rf ./bin
mkdir ./bin
mkdir ./bin/s3update

echo "+++++ build go packages +++++"

cd golang/s3update
go get
env GOOS=linux GOARCH=amd64 go build -o ../../bin/s3update/bootstrap
if [ $? -ne 0 ]
then
    echo "build s3update packages failed"
    exit 1
fi

echo "+++++ apply terraform +++++"
cd ../../terraform
terraform init
if [ $? -ne 0 ]
then
    echo "terraform init failed"
    exit 1
fi

terraform workspace new $environment
terraform workspace select $environment

terraform apply --auto-approve

echo -e "\n+++++ Deployment done +++++\n"
