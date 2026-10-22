#!/bin/bash
set -e

# TAG, AWS_ECS_CLUSTER, and AWS_ECS_SERVICE are resolved by the calling
# workflow (see .github/workflows/deploy.yml's "Resolve deploy target"
# step) based on which environment this deploy actually targets — this
# script just builds/pushes/deploys whatever it's told.

echo "Building image with tag: stable"

docker build \
	--platform linux/amd64 \
	--file Dockerfile \
	-t otb \
	.

echo "Logging in to AWS"
aws ecr get-login-password --region us-east-1 |
	docker login --username AWS --password-stdin 310867200447.dkr.ecr.us-east-1.amazonaws.com
echo "Logged in successfully"

echo "Tagging image with stable"
docker tag otb "310867200447.dkr.ecr.us-east-1.amazonaws.com/otb:stable"

echo "Pushing image"
docker push "310867200447.dkr.ecr.us-east-1.amazonaws.com/otb:stable"

echo "Force update service"
aws ecs update-service --cluster OpenTourBuilder --service otb-api-sidekiq-prod --force-new-deployment --region us-east-1
aws ecs update-service --cluster OpenTourBuilder --service otb-api-web-prod --force-new-deployment --region us-east-1
