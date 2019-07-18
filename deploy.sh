#!/bin/bash
if [ ! $1 ]; then
  printf 'Please specify a provider'
fi
cd $1
terraform init
terraform apply -auto-approve