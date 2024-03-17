# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter#attribute-reference
resource "aws_ssm_parameter" "RDS" {
  name  = "mysql-username"
  type  = "String"
  value = var.username
}

resource "aws_ssm_parameter" "RDS_2" {
  name  = "mysql-password"
  type  = "String"
  value = var.password
}
