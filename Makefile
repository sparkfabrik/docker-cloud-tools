# You can test the precunfigured command line enviroment running:
#
# make aws-tools
#

aws-tools: build-docker-image
  # Run the cli.
	docker run --rm -v ${PWD}:/mnt \
	--hostname "SPARK-AWS-TOOLS-TEST" --name spark-aws-tools \
	-it sparkfabrik/aws-tools:latest bash -il

build-docker-image:
	@case "$$( uname -m )" in \
		arm*) $(eval BUILDX_PLATFORM := linux/arm64) ;; \
		*) $(eval BUILDX_PLATFORM := linux/amd64) ;; \
	esac
	@echo "The build target platform is ${BUILDX_PLATFORM}"
	docker buildx build --load --platform ${BUILDX_PLATFORM} -t sparkfabrik/aws-tools:latest -f Dockerfile .