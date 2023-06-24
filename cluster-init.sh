#!/bin/bash

CLUSTER_NAME=$1;
REGISTRY_NAME=$2;
REGISTRY_PORT=$3;
NB_NODES=$4

namespaces=(vault api)


if k3d cluster list $CLUSTER_NAME 2>&1 > /dev/null; then
    docker start k3d-$REGISTRY_NAME
    k3d cluster start $CLUSTER_NAME;
    kubectl config use-context k3d-$CLUSTER_NAME;
else
    echo "INFO: Create cluster..."
    k3d registry create -p 0.0.0.0:$REGISTRY_PORT $REGISTRY_NAME --no-help;
    k3d cluster create $CLUSTER_NAME \
        -a $NB_NODES \
        -p '80:80@loadbalancer' \
        -p '443:443@loadbalancer' \
        --k3s-arg '--disable=traefik@server:0' \
        --registry-use k3d-$REGISTRY_NAME:$REGISTRY_PORT;
    
    kubectl taint node k3d-$CLUSTER_NAME-server-0 node-role.kubernetes.io/master:NoSchedule
    
    kubectl config use-context k3d-$CLUSTER_NAME;

    echo "INFO: Create namespaces..."
    for namespace in ${namespaces[*]}
    do
        kubectl create ns $namespace;
    done

    # Vault installation
    helm upgrade --install vault ./charts/vault \
        -f ./charts/vault/values.yaml \
        -n vault \
        --set server.dataStorage.storageClass=local-path \
        --set server.auditStorage.storageClass=local-path;

    # Wait for Vault in running state
    while [[ $(kubectl get pods vault-0 -n vault -o 'jsonpath={..status.phase}') != "Running" ]]
    do 
        echo "INFO: Wait for vault get running..." && sleep 5
    done

    # Init Vault / get credentials
    kubectl exec vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json > vault-keys.json

fi

kubectl rollout status -n kube-system deployment coredns;
kubectl rollout restart -n kube-system deployment coredns;
