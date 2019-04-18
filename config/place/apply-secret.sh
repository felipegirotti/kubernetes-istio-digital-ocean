#!/usr/bin/env bash

kubectl create secret generic place-kube \
    --from-file=./common.sh \
    --dry-run -o yaml | kubectl apply -f -