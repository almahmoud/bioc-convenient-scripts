#!/bin/bash

set -xe

if ! $(helm repo ls | grep -q bioc);
  then helm repo add bioc https://github.com/Bioconductor/helm-charts/raw/devel
fi



while getopts "n:r:s:t:" flag
do
    case "${flag}" in
        n) namespace=${OPTARG};;
        s) size=${OPTARG};;
        r) repo=${OPTARG};;
        t) tag=${OPTARG};;
    esac
done


if [ -z "$namespace" ];
    then echo "A namespace must be specific with eg: -n myinitials-mynamespace";
    exit;
fi


if [ -z "$size" ];
    then echo "A disk size must be specific with eg: -s 10[Gi|Mi]";
    exit;
fi


if [ -z "$tag" ];
    then export tag="devel";
fi

if [ -z "$repo" ];
    then export repository="bioconductor/bioconductor_docker";
fi

helm upgrade --create-namespace --install -n "$namespace" bioc-script bioc/bioconductor \
   --set ingress.enabled=false \
   --set service.type=NodePort \
   --set persistence.storageClass=nfs \
   --set persistence.size="$size" \
   --set persistence.mountPath="/home/rstudio/nfs-data" \
   --set image.repository="$repo" \
   --set image.tag="$tag"


kubectl wait --for=condition=available --timeout=600s  -n "$namespace" deployment/bioc-script-bioconductor


echo "Your RStudio will be available at: <your-node-ip>:$(kubectl get -n "$namespace" -o jsonpath="{.spec.ports[0].nodePort}" services bioc-script-bioconductor)"
