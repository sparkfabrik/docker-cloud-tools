# You can test the precunfigured command line enviroment running:
#
# make aws-tools
#

aws-tools: build-docker-image
	@touch .env
	@docker run --rm -v ${PWD}:/mnt \
		--hostname "SPARK-AWS-TOOLS-TEST" --name spark-aws-tools \
		--env-file .env \
		-it sparkfabrik/aws-tools:latest

build-docker-image:
	docker buildx build --load -t sparkfabrik/aws-tools:latest -f Dockerfile .

# The following jobs are intended for test purpose only
build-docker-image-amd64:
	docker buildx build --platform "linux/amd64" -t sparkfabrik/aws-tools:latest -f Dockerfile .

build-docker-image-arm64:
	docker buildx build --platform "linux/arm64" -t sparkfabrik/aws-tools:latest -f Dockerfile .
