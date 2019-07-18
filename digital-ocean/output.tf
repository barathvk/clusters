output "ingress_ip" {
  value = "${data.kubernetes_service.nginx_ingress.load_balancer_ingress.0.ip}"
}
