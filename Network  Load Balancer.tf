# ALB
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "load_balancer" {
  name               = "${var.vpc_name}-load-balancer"
  internal           = false
  load_balancer_type = "network"
  security_groups    = ["${aws_security_group.load_balancer.id}"]
  subnets            = ["${aws_subnet.public-primary-instance.id}", "${aws_subnet.public-secondary-instance.id}"]

  enable_deletion_protection = false

  tags = {
    Project = "${var.vpc_name}"

  }
}

# Target Group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "blue" {
  name        = "${var.vpc_name}-blue"
  port        = var.task_port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    port     = 3456
    protocol = "TCP"
  }
}

resource "aws_lb_target_group" "green" {
  name        = "${var.vpc_name}-green"
  port        = var.task_port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    port     = 3456
    protocol = "TCP"
  }
}
# Listener & Listener rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80" # Single listener is allowed for ECS; 80 for s3 & 443 for Cloudfront. The listner's should be assigned by ECS service as well. 
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}
