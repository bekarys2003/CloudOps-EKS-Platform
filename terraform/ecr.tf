resource "aws_ecr_repository" "svc" {
  for_each                     = var.boutique_services
  name                         = "online-boutique/${each.key}"
  image_scanning_configuration { scan_on_push = true }
  force_delete                 = true
}
