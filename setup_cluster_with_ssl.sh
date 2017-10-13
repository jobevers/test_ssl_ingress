#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

CLUSTER_NAME=$1
gcloud compute addresses create $CLUSTER_NAME-ip --region us-east1

LB_ADDRESS_IP=$(gcloud compute addresses list | grep $CLUSTER_NAME-ip | awk '{print $3}')
echo "Using ${LB_ADDRESS_IP} as the static ip for the ingress"
gcloud beta container clusters create $CLUSTER_NAME --num-nodes 1 --machine-type n1-standard-4 --disable-addons HttpLoadBalancing
gcloud container clusters get-credentials $CLUSTER_NAME

LB_INSTANCE_NAME=$(kubectl describe nodes | head -n1 | awk '{print $2}')
LB_INSTANCE_NAT=$(gcloud compute instances describe $LB_INSTANCE_NAME | grep -A3 networkInterfaces: | tail -n1 | awk -F': ' '{print $2}')
gcloud compute instances delete-access-config $LB_INSTANCE_NAME --access-config-name "$LB_INSTANCE_NAT"
gcloud compute instances add-access-config $LB_INSTANCE_NAME --access-config-name "$LB_INSTANCE_NAT" --address $LB_ADDRESS_IP

kubectl label nodes $LB_INSTANCE_NAME role=load-balancer
gcloud compute instances add-tags $LB_INSTANCE_NAME --tags http-server,https-server

kubectl create secret tls tls-secret --key tls/privkey.pem --cert tls/fullchain.pem
kubectl create -f nginx-ingress-config.yaml
kubectl create -f echo-service.yaml
kubectl create -f ingress.yaml
