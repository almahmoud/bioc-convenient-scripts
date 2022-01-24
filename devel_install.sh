#!/bin/bash

if ! $(helm repo ls | grep -q bioc);
then
echo "yes"; fi



while getopts n:s:t: flag
do
    case "${flag}" in
        n) namespace=${OPTARG};;
        s) size=${OPTARG};;
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
	then echo "A container image tag must be specific with eg: -t devel";
	exit;
fi

helm upgrade --create-namespace --install -n "$namespace" bioc-script bioc/bioconductor \
   --set ingress.enabled=false \
   --set service.type=NodePort \
   --set persistence.storageClass=nfs \
   --set persistence.size="$size" \
   --set image.tage="$tag"


kubectl wait --for=condition=available --timeout=600s  -n "$namespace" deployment/bioc-script-bioconductor


echo "Your RStudio will be available at: <your-node-ip>:$(kubectl get -n "$namespace" -o jsonpath="{.spec.ports[0].nodePort}" services bioc-script-bioconductor)"
