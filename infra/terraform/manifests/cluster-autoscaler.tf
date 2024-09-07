resource "kubernetes_namespace" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
  }
}

# Cluster auto scaler deployment
resource "kubernetes_deployment" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = kubernetes_namespace.cluster_autoscaler.metadata[0].name
    labels = {
      app = "cluster-autoscaler"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cluster-autoscaler"
      }
    }

    template {
      metadata {
        labels = {
          app = "cluster-autoscaler"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.cluster_autoscaler.metadata[0].name
        container {
          image = "k8s.gcr.io/autoscaling/cluster-autoscaler:v1.23.0"
          name  = "cluster-autoscaler"

          command = [
            "./cluster-autoscaler",
            "--cluster-name=${var.cluster_name}",
            "--cloud-provider=aws",
            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}",
            "--nodes=1:5:${var.asg_name}",
            "--skip-nodes-with-local-storage=false",
            "--balance-similar-node-groups"
          ]

          env {
            name  = "AWS_REGION"
            value = var.region
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "300Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "300Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = kubernetes_namespace.cluster_autoscaler.metadata[0].name
    annotations = {
      "iam.amazonaws.com/role" : var.cluster_autoscaler_role_arn
    }
  }
}

# Create the ClusterRole for Cluster Autoscaler
resource "kubernetes_cluster_role" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
  }

  rule {
    api_groups = [""]
    resources = [
      "events",
      "endpoints",
      "pods",
      "services",
      "nodes",
      "nodes/status"
    ]
    verbs = ["watch", "list", "get"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["patch", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "list", "watch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "daemonsets",
      "replicasets",
      "statefulsets"
    ]
    verbs = ["list", "get"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["watch", "list"]
  }

  rule {
    api_groups = ["batch", "extensions"]
    resources  = ["jobs"]
    verbs      = ["list", "get"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["watch", "list", "get", "delete", "update", "create"]
  }
}

# Create the ClusterRoleBinding for Cluster Autoscaler
resource "kubernetes_cluster_role_binding" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_autoscaler.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_autoscaler.metadata[0].name
    namespace = kubernetes_service_account.cluster_autoscaler.metadata[0].namespace
  }
}

# Create the Role in cluster-autoscaler namespace
resource "kubernetes_role" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = kubernetes_namespace.cluster_autoscaler.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "list", "watch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["create", "list", "watch", "delete", "get"]
  }
}

# Create the RoleBinding in cluster-autoscaler namespace
resource "kubernetes_role_binding" "cluster_autoscaler_role_binding" {
  metadata {
    name      = "cluster-autoscaler-role-binding"
    namespace = kubernetes_namespace.cluster_autoscaler.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.cluster_autoscaler.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_autoscaler.metadata[0].name
    namespace = kubernetes_service_account.cluster_autoscaler.metadata[0].namespace
  }
}
