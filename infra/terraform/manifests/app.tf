locals {
  BIRD_API_HOST_PORT = 80
}

resource "kubernetes_namespace" "api" {
  metadata {
    name = "api"
  }
}

resource "kubernetes_deployment" "bird" {
  metadata {
    name      = "bird"
    namespace = kubernetes_namespace.api.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "bird"
      }
    }

    template {
      metadata {
        labels = {
          app = "bird"
        }
      }

      spec {
        container {
          name  = "bird"
          image = "demarauder/bird:latest"

          port {
            container_port = 4201
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          env {
            name  = "BIRD_API_HOST"
            value = kubernetes_service.bird_image_service.metadata[0].name
          }
          env {
            name  = "BIRD_API_HOST_PORT"
            value = local.BIRD_API_HOST_PORT
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "bird_service" {
  metadata {
    name      = "${kubernetes_deployment.bird.metadata[0].name}-service"
    namespace = kubernetes_namespace.api.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.bird.metadata[0].name
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 4201
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "bird" {
  metadata {
    name      = "${kubernetes_deployment.bird.metadata[0].name}-hpa"
    namespace = kubernetes_namespace.api.metadata[0].name
    labels = {
      app = kubernetes_deployment.bird.metadata[0].name
    }
  }

  spec {
    min_replicas = 2
    max_replicas = 10

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.bird.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 50 # Target 50% CPU utilization
        }
      }
    }

    metric {
      type = "Resource"

      resource {
        name = "memory"

        target {
          type                = "Utilization"
          average_utilization = 70 # Target 70% memory utilization
        }
      }
    }

    behavior {
      scale_up {
        stabilization_window_seconds = 60
        select_policy                = "Max"
        policy {
          type           = "Percent"
          value          = 100 # Scale up by 100% every 60 seconds
          period_seconds = 60
        }
      }

      scale_down {
        stabilization_window_seconds = 300
        select_policy                = "Min"

        policy {
          type           = "Percent"
          value          = 50 # Scale down by 50% every 60 seconds
          period_seconds = 60
        }
      }
    }
  }
}


resource "kubernetes_deployment" "bird_image" {
  metadata {
    name      = "bird-image"
    namespace = kubernetes_namespace.api.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "bird-image"
      }
    }

    template {
      metadata {
        labels = {
          app = "bird-image"
        }
      }

      spec {
        container {
          name  = "bird-image"
          image = "demarauder/bird-image:latest"

          port {
            container_port = 4200
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "bird_image_service" {
  metadata {
    name      = "${kubernetes_deployment.bird_image.metadata[0].name}-service"
    namespace = kubernetes_namespace.api.metadata[0].name
  }

  spec {
    selector = {
      app = "${kubernetes_deployment.bird_image.metadata[0].name}"
    }

    port {
      protocol    = "TCP"
      port        = local.BIRD_API_HOST_PORT # API will look for the service on this port
      target_port = 4200
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "bird_image" {
  metadata {
    name      = "${kubernetes_deployment.bird_image.metadata[0].name}-hpa"
    namespace = kubernetes_namespace.api.metadata[0].name
    labels = {
      app = kubernetes_deployment.bird_image.metadata[0].name
    }
  }

  spec {
    min_replicas = 2
    max_replicas = 10

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.bird_image.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 50 # Target 50% CPU utilization
        }
      }
    }

    metric {
      type = "Resource"

      resource {
        name = "memory"

        target {
          type                = "Utilization"
          average_utilization = 70 # Target 70% memory utilization
        }
      }
    }

    behavior {
      scale_up {
        stabilization_window_seconds = 60
        select_policy                = "Max"

        policy {
          type           = "Percent"
          value          = 100 # Scale up by 100% every 60 seconds
          period_seconds = 60
        }
      }

      scale_down {
        stabilization_window_seconds = 300
        select_policy                = "Min"

        policy {
          type           = "Percent"
          value          = 50 # Scale down by 50% every 60 seconds
          period_seconds = 60
        }
      }
    }
  }
}