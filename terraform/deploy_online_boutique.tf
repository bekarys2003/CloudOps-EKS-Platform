resource "null_resource" "deploy_online_boutique" {
  depends_on = [aws_eks_cluster.cloudops-eks-platform]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.cloudops-eks-platform.name}
      kubectl apply -f https://raw.githubusercontent.com/bekarys2003/microservices-demo/main/release/kubernetes-manifests.yaml

      echo "Waiting for LoadBalancer hostname..."
      for i in $(seq 1 60); do
        H=$(kubectl get svc frontend-external -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || true)
        if [ -n "$H" ]; then echo "LB hostname: $H"; exit 0; fi
        sleep 10
      done
      echo "Timed out waiting for frontend-external hostname" >&2
      exit 1
    EOT
    interpreter = ["/bin/bash", "-lc"]
  }
}
