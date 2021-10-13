locals {
  resource_prefix = "${var.app_name}-${var.env_name}"
  all_ips         = ["0.0.0.0/0"]
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_default_tags" "current" {}

resource "aws_security_group" "app_servers" {
  name = "${local.resource_prefix}-app-server-sg"

  ingress {
    from_port   = var.app_server_port
    to_port     = var.app_server_port
    protocol    = "tcp"
    cidr_blocks = local.all_ips
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.all_ips
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = local.all_ips
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_launch_configuration" "app_servers" {
  image_id        = "ami-013a129d325529d4d"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.app_servers.id]
  key_name        = "MyKey"

  user_data = <<-EOF
              #!/bin/bash
              wget https://michaelpesa-devops-course.s3.amazonaws.com/main -O app-main
              chmod +x ./app-main
              export NR_LICENSE_KEY=${var.newrelic_license_key}
              export APP_NAME=${var.app_name}
              export ENV_NAME=${var.env_name}
              nohup ./app-main &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app_servers" {
  launch_configuration = aws_launch_configuration.app_servers.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns    = [aws_lb_target_group.app_servers.arn]
  health_check_type    = "ELB"

  min_size = 2
  max_size = 2

  dynamic "tag" {
    for_each = merge(data.aws_default_tags.current.tags, {Name = "${local.resource_prefix}-app-server"})
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }
}

resource "aws_security_group" "alb" {
  name = "${local.resource_prefix}-alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.all_ips
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.all_ips
  }
}

resource "aws_lb" "alb" {
  name               = "${local.resource_prefix}-alb"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]
  load_balancer_type = "application"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "http_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_servers.arn
  }
}

resource "aws_lb_target_group" "app_servers" {
  name     = "${local.resource_prefix}-alb-target"
  port     = var.app_server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/list"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
