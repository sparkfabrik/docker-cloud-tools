# You can test the preconfigured command line enviroment running:
#
# make cloud-tools
#
# You can find the list of the available image tags here:
# https://console.cloud.google.com/gcr/images/google.com:cloudsdktool/EU/google-cloud-cli

GOOGLE_CLOUD_CLI_IMAGE_TAG ?= 518.0.0-alpine
IMAGE_NAME ?= sparkfabrik/cloud-tools
IMAGE_TAG ?= latest

cloud-tools: build-docker-image
	@touch .env
	@docker run --rm \
		-u $(shell id -u):$(shell id -g) \
		-v ${PWD}/dotfiles:/cloud-tools-cli/dotfiles \
		-v ~/.config/gcloud:/cloud-tools-cli/.config/gcloud \
		-w /mnt \
		--hostname "SPARK-CLOUD-TOOLS-LOCAL" --name spark-cloud-tools-local \
		--env-file .env \
		-it $(IMAGE_NAME):$(IMAGE_TAG)

build-docker-image:
	docker buildx build --build-arg GOOGLE_CLOUD_CLI_IMAGE_TAG=$(GOOGLE_CLOUD_CLI_IMAGE_TAG) --load -t $(IMAGE_NAME):$(IMAGE_TAG) -f Dockerfile .

# The following jobs are intended for test purpose only
build-docker-image-amd64: PLATFORM := amd64
build-docker-image-amd64: build-docker-image-platform-template

build-docker-image-arm64: PLATFORM := arm64
build-docker-image-arm64: build-docker-image-platform-template

build-docker-image-platform-template:
	@if [ -z "$(PLATFORM)" ]; then echo "PLATFORM is not defined"; exit 1; fi
	docker buildx build --build-arg GOOGLE_CLOUD_CLI_IMAGE_TAG=$(GOOGLE_CLOUD_CLI_IMAGE_TAG) --platform "linux/$(PLATFORM)" -t $(IMAGE_NAME):$(IMAGE_TAG)-$(PLATFORM) -f Dockerfile .

print-google-cloud-cli-image-tag:
	@echo $(GOOGLE_CLOUD_CLI_IMAGE_TAG)
