# cloud-tools

## How to use

```bash
docker run --rm -it \
    -eCLUSTER_TYPE=EKS \
    -eAWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID> \
    -eAWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY> \
    -eAWS_DEFAULT_REGION=<AWS_DEFAULT_REGION> \
  ghcr.io/sparkfabrik/cloud-tools:latest
```

You can also use the `.env.template` file as a reference to create a `.env`.

## Using GCP secret

If you store the AWS access information in a GCP secret, you can use directly this one to automatically configure the docker image. The secret payload must follow this structure:

```json
{
  "AWS_ACCESS_KEY_ID": <AWS_ACCESS_KEY_ID>,
  "AWS_SECRET_ACCESS_KEY": <AWS_SECRET_ACCESS_KEY>,
  "AWS_DEFAULT_REGION": <AWS_DEFAULT_REGION>,
  "AVAILABLE_NAMESPACES": [ <The available namsespace as a list of string> ],
}
```

When yuo use this configuration you can run the container as follow:

```bash
docker run --rm -it \
    -v ~/.config/gcloud:/root/.config/gcloud \
    -eCLUSTER_TYPE=EKS \
    -eSECRET_PROJECT=<GCP Project id which hosts the secret>
    -eSECRET_NAME=<GCP secret name>
    -eSECRET_VER=<GCP secret version>
  ghcr.io/sparkfabrik/cloud-tools:latest
```

## Tools

This image is intended to be a cloud toolkit with some helpers to work with [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine) and [Amazon Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/).

The image is based on the `google/cloud-sdk` docker image. You can use the [gcloud CLI](https://cloud.google.com/sdk/gcloud) and the [AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/) commands to work with your cloud vendor. If your user has access to **GKE** or **EKS** cluster, the docker image tries to configure the proper `KUBECONFIG` at startup.

In the final docker image, you will find also the following tools:

- gcloud ([GCP CLI](https://cloud.google.com/sdk/gcloud))
- gsutil ([Google Cloud Storage Utility](https://cloud.google.com/storage/docs/gsutil))
- aws ([AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/))
- kubectl
- kubens (custom script which uses `AVAILABLE_NAMESPACES` environment variables as namespacee list)
- helm
- stern

### GKE helper (CLUSTER_TYPE: GKE)

If you have configured your gcloud authentication and you user can access to one cluster, the first GKE cluster listed using `gcloud container clusters list` will be automatically configured as default in the `kubeconfig` file.

If you need to configure another cluster you can use the `gcloud container clusters list` command to see the list of all the available clusters. Use `gcloud container clusters get-credentials "<put here the cluster name>" --project "${GCP_PROJECT}" --zone "<put here the GCP project name>"` to update the configuration.

### EKS helper (CLUSTER_TYPE: EKS)

If the IAM user configured to run inside the docker image has access to an EKS cluster, the first EKS cluster listed using the command `aws eks list-clusters` will be automatically configured as default in the `kubeconfig` file.

If you need to configure another cluster you can use the `aws eks list-clusters` command to see the list of all the available clusters. Use `aws eks update-kubeconfig --name "<put here the cluster name>" --kubeconfig "${KUBECONFIG}"` to update the configuration.
