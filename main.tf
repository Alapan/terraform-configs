provider "aws" {
  region = "eu-west-1"
}

variable "server_port" {
  description = "The port the server is listening on"
  type = number
}

resource "aws_instance" "app-server-2" {
  ami = "ami-0bbc25e23a7640b9b"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags = {
    name = "Terraform example"
  }
}

resource "aws_security_group" "sg" {
  name = "terraform-example-server"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value = aws_instance.app-server-2.public_ip
  description = "Public IP of the web server"
}
