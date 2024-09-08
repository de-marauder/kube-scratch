# Ingress configuration to allow external access to deployed services
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
    <<-EOT
    controller:
      config:
        compute-full-forwarded-for: "true"
        use-forwarded-headers: "true"
        proxy-body-size: "0"
      ingressClassResource:
        name: external-nginx
        enabled: true
        default: false
        controller: "ingress.k8s.aws/alb"
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                    - ingress-nginx
            topologyKey: "kubernetes.io/hostname"
      replicaCount: 1
      admissionWebhooks:
        enabled: false
      service:
        type: LoadBalancer
        externalTrafficPolicy: "Cluster"
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-name: ${var.alb_name}
          service.beta.kubernetes.io/aws-load-balancer-type: alb
          service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: "deregistration_delay.timeout_seconds=30"
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: http
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: /healthz
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: 10254
          alb.ingress.kubernetes.io/load-balancer-arn: ${var.alb_arn}  # The ARN of the ALB
          alb.ingress.kubernetes.io/target-type: "ip"  # Targets pods by their IP address
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
          alb.ingress.kubernetes.io/scheme: "internet-facing"
      metrics:
        enabled: false
    EOT
  ]
  depends_on = [
    helm_release.aws_load_balancer_controller
  ]
}

resource "kubernetes_ingress_v1" "api_ingress" {
  metadata {
    name      = "${kubernetes_namespace.api.metadata[0].name}-ingress"
    namespace = kubernetes_namespace.api.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "kubernetes.io/ingress.class"                = "external-nginx"
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "false"
    }
  }

  spec {
    ingress_class_name = "external-nginx"
    tls {
      hosts       = ["bird-image.${var.domain_name}", "bird.${var.domain_name}"]
      secret_name = "bird-tls"
    }

    rule {
      host = "bird.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.bird_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = "bird-image.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.bird_image_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "prometheus_ingress" {
  metadata {
    name      = "prometheus-ingress"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "kubernetes.io/ingress.class"                = "external-nginx"
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "false"
    }
  }

  spec {
    ingress_class_name = "external-nginx"
    tls {
      hosts       = ["prom.${var.domain_name}"]
      secret_name = "prometheus-server-tls"
    }

    rule {
      host = "prom.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "prometheus-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "grafana_ingress" {
  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "kubernetes.io/ingress.class"                = "external-nginx"
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "false"
    }
  }

  spec {
    ingress_class_name = "external-nginx"
    tls {
      hosts       = ["graf.${var.domain_name}"]
      secret_name = "grafana-server-tls"
    }

    rule {
      host = "graf.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "grafana"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }
}
