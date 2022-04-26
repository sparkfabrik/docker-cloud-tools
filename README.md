# aws-tools

## How to use

```bash
docker run --rm -it \
    -eAWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID> \
    -eAWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY> \
    -eAWS_DEFAULT_REGION=<AWS_DEFAULT_REGION> \
  ghcr.io/sparkfabrik/aws-tools:latest
```

You can also use the `.env.template` file as a reference to create a `.env`.

## Tools

This image is intended to be an AWS toolkit with some helpers to work with [Amazon Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/).

The image is based on the `amazon/aws-cli` docker image, so you could use all the AWS CLI commands defined [here](https://docs.aws.amazon.com/cli/latest/reference/).

In the final docker image, you will find also the following tools:

- kubectl
- kubens
- helm
- stern

### EKS helper

If the IAM user configured to run inside the docker image has access to an EKS cluster, the first EKS cluster listed using the command `aws eks list-clusters` will be automatically configured as default in the `kubeconfig` file.

If you need to configure another cluster you can use the `aws eks list-clusters` command to see the list of all the available clusters. Use `aws eks update-kubeconfig --name "<put here the cluster name>" --kubeconfig "${KUBECONFIG}"` to update the configuration.
