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
	docker buildx build --load -t sparkfabrik/aws-tools:latest -f Dockerfile .
