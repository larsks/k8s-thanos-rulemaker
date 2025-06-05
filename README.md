# Dynamically generate a configmap from fragments

## Testing

### Build the image

1. Build the image:

       podman build -t rulemaker image

1. Save the image to a file:

        podman image save rulemaker > rulemaker.tar

### Create a kind cluster

1. Start a `kind` cluster:

        kind create cluster --kubeconfig kubeconfig

1. Activate the `kubeconfig` file:

        export KUBECONFIG=kubeconfig

### Load the image into kind

1. Load the image into the kind cluster:

        kind load image-archive rulemaker.tar

### Deploy the example

1. Create a target namespace:

        kubectl create ns rulemaker

1. Deploy the project:

        kubectl apply -k .

1. Observe that the rulemaker pod has generated the configmap `custom-rules` from the fragments stored in the `custom-rules-fragments` configmap.

1. Either edit the `custom-rules-fragments` configmap, or create a new configmap containing a partial rules configuration and label it with the `thanos-rules` label. Observe that the `custom-rules` configmap is immediately re-generated.
