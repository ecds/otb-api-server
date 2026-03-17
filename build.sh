#!/bin/bash
set -e

# TAG=$([ "$BRANCH" == "main" ] && echo "stable" || echo "latest")

# AWS_ECS_CLUSTER=$([ "$BRANCH" == "main" ] && echo "$AWS_ECS_CLUSTER_PROD" || echo "$AWS_ECS_CLUSTER_DEV")

# AWS_ECS_SERVICE=$([ "$BRANCH" == "main" ] && echo "$AWS_ECS_SERVICE_PROD" || echo "$AWS_ECS_SERVICE_DEV")

# echo "Building image for branch: $BRANCH with tag: $TAG"

docker build \
       --platform linux/amd64 \
       --file Dockerfile \
       -t otb \
       .

echo "Logging in to AWS"
aws ecr get-login-password --region us-east-1 |
       docker login --username AWS --password-stdin 310867200447.dkr.ecr.us-east-1.amazonaws.com
echo "Logged in successfully"

echo "Tagging image with $TAG"
docker tag otb 310867200447.dkr.ecr.us-east-1.amazonaws.com/otb:latest

echo "Pushing image"
docker push 310867200447.dkr.ecr.us-east-1.amazonaws.com/otb:latest

echo "Force update service"
aws ecs update-service --cluster otb-dev --service otb-dev --force-new-deployment --region us-east-1