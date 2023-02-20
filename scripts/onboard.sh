#!/bin/bash

echo "Onboarding new source repository to OpenShift. The OpenShift cluster MUST have \
the Red Hat OpenShift Pipelines operator installed, and you MUST have the 'oc' and 'tkn'\
CLIs installed locally to use this script."

echo

read -p "Proceed? [y/N]: " -n 1 -r REPLY

echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting."
    exit 0
fi

read -p "Your app's name: " APP_NAME
read -p "Your GitHub repo URL: " GITHUB_REPO_URL
read -sp "GitHub API token (must have write permission for webhooks): " GITHUB_TOKEN

GITHUB_REPO="$(echo "$GITHUB_REPO_URL" | grep -o '\.com[:/].*.git' | sed -e 's/\.com.//' -e 's/\.git//')"
GITHUB_REPO_OWNER="$(echo "$GITHUB_REPO" | cut -d '/' -f 1)"
GITHUB_REPO_NAME="$(echo "$GITHUB_REPO" | cut -d '/' -f 2)"

echo "Starting new project..."

oc new-project "$APP_NAME"

echo "Applying Tekton manifests..."

oc apply -f ./tkn/ --recursive
oc expose svc el-tekton-demo

echo "Running first staging pipeline..."

tkn pipeline start staging-build-and-deploy \
    -w name=shared-workspace,volumeClaimTemplateFile=./tkn/resources/persistent_volume_claim.yaml \
    -p deployment-name=tekton-demo-app \
    -p git-url=https://github.com/pbaity/tekton-demo.git \
    -p IMAGE=image-registry.openshift-image-registry.svc:5000/tekton-demo/tekton-demo-app \
    --use-param-defaults

tkn pipelinerun logs -f --last

APP_ROUTE="$(oc get route tekton-demo-app --template='http://{{.spec.host}}')"

echo "Setting up GitHub webhook..."

WEBHOOK_URL="$(oc get route el-tekton-demo --template='http://{{.spec.host}}')"
WEBHOOK_SECRET="1234567"

curl \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/hooks \
  -d '{"name":"web","active":true,"events":["push","pull_request"],"config":{"url":"'"$WEBHOOK_URL"'","content_type":"json","secret":"'"$WEBHOOK_SECRET"'","insecure_ssl":"0"}}'

echo "App deployed: $APP_ROUTE"
