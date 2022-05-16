# cloud-tools

## Usage

You can provide the cluster configuration and the authentication for the cloud vendor using environment variables. You can also use the `.env.template` file as a reference to create a `.env`.

### GKE configuration

```bash
docker run --rm -it \
    -v ~/.config/gcloud:/root/.config/gcloud \
    -e CLUSTER_TYPE=GKE \
    -e GCP_PROJECT=<GCP project of the GKE cluster>
  ghcr.io/sparkfabrik/cloud-tools:latest
```

### EKS configuration

```bash
docker run --rm -it \
    -e CLUSTER_TYPE=EKS \
    -e AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID> \
    -e AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY> \
    -e AWS_DEFAULT_REGION=<AWS_DEFAULT_REGION> \
  ghcr.io/sparkfabrik/cloud-tools:latest
```

### Configuration environment variables

- `CLUSTER_NAME`: the name of the cluster that you want to configure (**optional**, if the variable is not provided, the first cluster in the `list` command will be configured; e.g.: `prod-cluster`)
- `CLUSTER_LOCATION` (only for GCP): the location of the cluster (**optional**, if the variable is not provided, the location will be searched using the cluster name; e.g.: `europe-west4-a`)
- `AVAILABLE_NAMESPACES`: the list of the available namespaces as space separated values (e.g.: `default stage production`)
- `STARTUP_NAMESPACE`: the namespace configured at CLI startup (e.g.: `stage`)

### GCP secret

You can use a GCP secret to store AWS credentials and the additional configuration. The secret payload must follow this structure:

```json
{
  "AWS_ACCESS_KEY_ID": <AWS_ACCESS_KEY_ID>,
  "AWS_SECRET_ACCESS_KEY": <AWS_SECRET_ACCESS_KEY>,
  "AWS_DEFAULT_REGION": <AWS_DEFAULT_REGION>,
  "AVAILABLE_NAMESPACES": [ <The available namsespaces as a list of strings> ],
  "STARTUP_NAMESPACE": <Namespace configured at startup>
}
```

To use the secret you have to run the docker container using the following environment variables:

- `SECRET_PROJECT`: the GCP project which hosts the secret
- `SECRET_NAME`: the secret name
- `SECRET_VER`: the secret version (**optional**, if the variable is not provided, the latest version will be used)

```bash
docker run --rm -it \
    -v ~/.config/gcloud:/root/.config/gcloud \
    -e CLUSTER_TYPE=EKS \
    -e SECRET_PROJECT=<GCP Project id which hosts the secret>
    -e SECRET_NAME=<GCP secret name>
    -e SECRET_VER=<GCP secret version>
  ghcr.io/sparkfabrik/cloud-tools:latest
```

## Bash history

If you want to maintain the bash history from one run to another, you can mount a local folder in `/root/dotfiles`. The docker image is configured to save the `HISTFILE` in `/root/dotfiles/.bash_history`.

## Tools

This image is intended to be a cloud toolkit with some helpers to work with [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine) and [Amazon Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/).

The image is based on the `google/cloud-sdk` docker image. You can use the [gcloud CLI](https://cloud.google.com/sdk/gcloud) and the [AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/) commands to work with your cloud vendor. If your user has access to a **GKE** or **EKS** cluster, the docker image tries to configure the proper `KUBECONFIG` at startup.

In the final docker image, you will also find the following tools:

- gcloud ([GCP CLI](https://cloud.google.com/sdk/gcloud))
- gsutil ([Google Cloud Storage Utility](https://cloud.google.com/storage/docs/gsutil))
- aws ([AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/))
- kubectl
- kubens (custom script which uses `AVAILABLE_NAMESPACES` environment variable as the list of namespaces)
- helm
- stern

### GKE helper (CLUSTER_TYPE: GKE)

If you have configured your gcloud authentication and your user can access a cluster, the first GKE cluster listed using the `gcloud container clusters list` command will be automatically configured as default in the `kubeconfig` file.

If you need to configure another cluster you can use the `gcloud container clusters list` command to see the list of all the available clusters. Use `gcloud container clusters get-credentials "<put here the cluster name>" --project "${GCP_PROJECT}" --zone "<put here the GCP project name>"` to update the configuration.

You can also specify the `CLUSTER_NAME` environment variable to force the cluster configuration.

### EKS helper (CLUSTER_TYPE: EKS)

If the IAM user configured to run inside the docker image has access to an EKS cluster, the first EKS cluster listed using the `aws eks list-clusters` command will be automatically configured as default in the `kubeconfig` file.

If you need to configure another cluster you can use the `aws eks list-clusters` command to see the list of all the available clusters. Use `aws eks update-kubeconfig --name "<put here the cluster name>" --kubeconfig "${KUBECONFIG}"` to update the configuration.
