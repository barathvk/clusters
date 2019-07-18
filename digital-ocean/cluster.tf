resource "digitalocean_kubernetes_cluster" "main" {
  name    = "dev-cluster"
  region  = "fra1"
  version = "1.14.3-do.0"
  node_pool {
    name       = "dev-cluster"
    size       = "s-2vcpu-2gb"
    node_count = 1
  }

  provisioner "local-exec" {
    command = "mkdir -p ~/.kube && echo \"${digitalocean_kubernetes_cluster.main.kube_config.0.raw_config}\" > ~/.kube/config"
  }
}
