provider "aws" {
  region = "eu-west-1"
}

variable "server_port" {
  description = "The port the server is listening on"
  type = number
  default = 8080
}

resource "aws_launch_configuration" "app" {
  image_id = "ami-0bbc25e23a7640b9b"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.app-server-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo 'Hello, World!' > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app-asg" {
  launch_configuration = aws_launch_configuration.app.id
  availability_zones = data.aws_availability_zones.all.names
  load_balancers = [aws_elb.app-elb.id]
  health_check_type = "ELB"

  min_size = 3
  max_size = 6

  tag {
    key = "Name"
    value = "terraform-asg"
    propagate_at_launch = true
  }
}

data "aws_availability_zones" "all" {}

resource "aws_elb" "app-elb" {
  name = "terraform-elb"
  security_groups = [aws_security_group.elb-sg.id]
  availability_zones = data.aws_availability_zones.all.names

  health_check {
    target = "HTTP:${var.server_port}/"
    interval = 30
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  listener {
    lb_port = "80"
    lb_protocol = "http"
    instance_port = var.server_port
    instance_protocol = "http"
  }
}

resource "aws_security_group" "app-server-sg" {
  name = "terraform-app-server-security group"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb-sg" {
  name = "terraform-elb-security-group"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "clb_dns_name" {
  value = aws_elb.app-elb.dns_name
  description = "DNS name of created ELB"
}
