# In a local MVP, K3d is provisioned via the bootstrap.sh script to ensure
# the kubeconfig exists before the Terraform Kubernetes provider initializes.
# This module acts as a state wrapper and validates the cluster is responsive.

resource "null_resource" "cluster_ready_check" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl cluster-info --context k3d-${var.cluster_name}"
  }
}
