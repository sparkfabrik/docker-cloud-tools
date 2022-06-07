# You can test the preconfigured command line enviroment running:
#
# make cloud-tools
#

IMAGE_NAME ?= sparkfabrik/cloud-tools
IMAGE_TAG ?= latest

cloud-tools: build-docker-image
	@touch .env
	@docker run --rm \
		-w /mnt \
		-v ${PWD}/dotfiles:/root/dotfiles \
		-v ~/.config/gcloud:/root/.config/gcloud \
		--hostname "SPARK-CLOUD-TOOLS-LOCAL" --name spark-cloud-tools-local \
		--env-file .env \
		-it $(IMAGE_NAME):$(IMAGE_TAG)

build-docker-image:
	docker buildx build --load -t $(IMAGE_NAME):$(IMAGE_TAG) -f Dockerfile .

# The following jobs are intended for test purpose only
build-docker-image-amd64: PLATFORM := amd64
build-docker-image-amd64: build-docker-image-platform-template

build-docker-image-arm64: PLATFORM := arm64
build-docker-image-arm64: build-docker-image-platform-template

build-docker-image-platform-template:
	@if [ -z "$(PLATFORM)" ]; then echo "PLATFORM is not defined"; exit 1; fi
	docker buildx build --platform "linux/$(PLATFORM)" -t $(IMAGE_NAME):$(IMAGE_TAG)-$(PLATFORM) -f Dockerfile .
