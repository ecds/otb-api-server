#!/bin/bash
set -e

TAG=$([ "$BRANCH" == "main" ] && echo "stable" || echo "latest")

AWS_ECS_CLUSTER=$([ "$BRANCH" == "main" ] && echo "$AWS_ECS_CLUSTER_PROD" || echo "$AWS_ECS_CLUSTER_DEV")

AWS_ECS_SERVICE=$([ "$BRANCH" == "main" ] && echo "$AWS_ECS_SERVICE_PROD" || echo "$AWS_ECS_SERVICE_DEV")

echo "Building image for branch: $BRANCH with tag: $TAG"

docker build \
       --file Dockerfile \
       -t otb \
       .

echo "Logging in to AWS"
aws ecr get-login-password --region us-east-1 |
       docker login --username AWS --password-stdin "${AWS_ECR}"
echo "Logged in successfully"

echo "Tagging image with $TAG"
docker tag otb "${AWS_ECR}/otb:${TAG}"

echo "Pushing image"
docker push "${AWS_ECR}/otb:${TAG}"

echo "Force update service"
aws ecs update-service --cluster ${AWS_ECS_CLUSTER} --service ${AWS_ECS_SERVICE} --force-new-deployment --region ${AWS_REGION}