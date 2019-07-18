resource "kubernetes_cluster_role_binding" "permissive" {
  metadata {
    name = "permissive-rolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "admin"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "User"
    name      = "default"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "null_resource" "install_helm" {
  depends_on = ["kubernetes_cluster_role_binding.permissive"]
  provisioner "local-exec" {
    command = "helm init --wait"
  }
}
data "helm_repository" "stable" {
    name = "stable"
    url  = "https://kubernetes-charts.storage.googleapis.com"
}
resource "helm_release" "nginx_ingress" {
  depends_on = ["null_resource.install_helm"]
  name = "nginx-ingress"
  namespace = "nginx-ingress"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  chart = "nginx-ingress"

  set {
    name = "controller.publishService.enabled"
    value = "true"
  }
}

data "kubernetes_service" "nginx_ingress" {
  depends_on = ["helm_release.nginx_ingress"]
  metadata {
    name = "nginx-ingress-controller"
    namespace = "nginx-ingress"
  }
}

data "template_file" "le_issuer" {
  template = "${file("${path.module}/templates/le-issuer.yml")}"
  vars = {
    le_email = "${var.le_email}"
  }
}

resource "null_resource" "certmanager_crd" {
  depends_on = ["null_resource.install_helm"]
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml"
  }
  provisioner "local-exec" {
    command = "kubectl create namespace cert-manager"
  }
  provisioner "local-exec" {
    command = "kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true"
  }
}


data "helm_repository" "jetstack" {
  name = "jetstack"
  url = "https://charts.jetstack.io"
}

resource "helm_release" "cert_manager" {
  depends_on = ["null_resource.certmanager_crd"]
  version = "v0.8.1"
  name = "cert-manager"
  namespace = "cert-manager"
  chart = "cert-manager"
  repository = "${data.helm_repository.jetstack.metadata.0.name}"
  set {
    name = "webhook.enabled"
    value = "false"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.le_issuer.rendered}\" | kubectl apply -f -"
  }
}
