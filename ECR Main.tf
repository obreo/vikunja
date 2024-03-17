resource "aws_ecr_repository" "respository" {
  name                 = "${var.ecr_name}-main"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}
