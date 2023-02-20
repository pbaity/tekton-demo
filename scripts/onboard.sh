#!/bin/bash

# This is a script that makes it easy to "onboard" a new "customer" (a source repository)
# to an OpenShift cluster. The cluster must already have the Red Hat OpenShift Pipelines
# operator installed, and you must locally have the `oc` and `tkn` CLIs installed.

oc apply -f ./tkn/ --recursive

tkn pipeline list

echo "Starting staging pipeline..."

tkn pipeline start staging-build-and-deploy \
    -w name=shared-workspace,volumeClaimTemplateFile=./tkn/resources/persistent_volume_claim.yaml \
    -p deployment-name=tekton-demo-app \
    -p git-url=https://github.com/pbaity/tekton-demo.git \
    -p IMAGE=image-registry.openshift-image-registry.svc:5000/tekton-demo/tekton-demo-app \
    --use-param-defaults