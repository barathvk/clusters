resource "digitalocean_domain" "default" {
  name       = "${var.domain}"
}

resource "digitalocean_record" "bare" {
  domain = "${digitalocean_domain.default.name}"
  type   = "A"
  name   = "@"
  value  = "${data.kubernetes_service.nginx_ingress.load_balancer_ingress.0.ip}"
}

resource "digitalocean_record" "star" {
  domain = "${digitalocean_domain.default.name}"
  type   = "A"
  name   = "*"
  value  = "${data.kubernetes_service.nginx_ingress.load_balancer_ingress.0.ip}"
}