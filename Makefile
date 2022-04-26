# You can test the precunfigured command line enviroment running:
#
# make aws-tools
#

IMAGE_NAME ?= sparkfabrik/aws-tools
IMAGE_TAG ?= latest

aws-tools: build-docker-image
	@touch .env
	@docker run --rm -v ${PWD}:/mnt \
		--hostname "SPARK-AWS-TOOLS-LOCAL" --name spark-aws-tools-local \
		--env-file .env \
		-it $(IMAGE_NAME):$(IMAGE_TAG)

build-docker-image:
	docker buildx build --load -t $(IMAGE_NAME):$(IMAGE_TAG) -f Dockerfile .

# The following jobs are intended for test purpose only
build-docker-image-amd64:
	docker buildx build --platform "linux/amd64" -t $(IMAGE_NAME):$(IMAGE_TAG) -f Dockerfile .

build-docker-image-arm64:
	docker buildx build --platform "linux/arm64" -t $(IMAGE_NAME):$(IMAGE_TAG) -f Dockerfile .
