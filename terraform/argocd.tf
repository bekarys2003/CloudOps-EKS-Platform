resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true
  version    = "6.9.3"

  # Quick start (exposes Server via Service type=LoadBalancer)
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }
  set {
    name  = "configs.params.server.insecure"
    value = "true"
  }
}

resource "null_resource" "wait_for_argocd_crd" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      # ensure kubeconfig is set; adjust region/cluster if needed
      aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.cloudops-eks-platform.name}
      # wait until the Application CRD is available
      for i in $(seq 1 60); do
        if kubectl api-resources --api-group=argoproj.io | grep -q '^applications'; then
          echo "Argo CD Application CRD ready"; exit 0
        fi
        sleep 5
      done
      echo "Timed out waiting for Application CRD" >&2
      exit 1
    EOT
    interpreter = ["/bin/bash", "-lc"]
  }
}


resource "null_resource" "apply_argocd_app" {
  depends_on = [
    helm_release.argocd,
    aws_eks_cluster.cloudops-eks-platform
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.cloudops-eks-platform.name}

      echo "Waiting for Argo CD Application CRD..."
      for i in $(seq 1 60); do
        if kubectl api-resources --api-group=argoproj.io | grep -q '^applications'; then
          break
        fi
        sleep 5
      done

      kubectl apply -f ${path.module}/../deploy/argocd/online-boutique.yaml
    EOT
    interpreter = ["/bin/bash", "-lc"]
  }
}
