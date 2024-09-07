resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  chart      = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"

  values = [
    <<EOF
    alertmanager:
      enabled: true
    server:
      service:
        type: ClusterIP
    EOF
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = "8.5.1"

  values = [
    <<EOF
    service:
      type: ClusterIP
    adminPassword: "${var.grafana_password}"
    EOF
  ]
}
