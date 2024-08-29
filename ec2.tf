# 8. Create EC2 instances
resource "aws_instance" "public-instance" {
  ami                    = var.ec2-ami
  instance_type          = var.default-instance
  availability_zone      = var.az-1
  subnet_id              = aws_subnet.public-subnet.id
  key_name               = var.key-name
  vpc_security_group_ids = [aws_security_group.allow.id]
  user_data              = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              echo "This is a restricted system. All access is monitored." > /var/www/html/index.html
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name = "public-instance"
  }
}

resource "aws_instance" "bastion-host" {
  ami                    = var.ec2-ami
  instance_type          = var.default-instance
  availability_zone      = var.az-1
  subnet_id              = aws_subnet.public-subnet.id
  key_name               = var.key-name
  vpc_security_group_ids = [aws_security_group.only-ssh-bastion.id]

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_instance" "private-instance" {
  ami                    = var.ec2-ami
  instance_type          = var.default-instance
  availability_zone      = var.az-1
  subnet_id              = aws_subnet.private-subnet.id
  key_name               = var.key-name
  vpc_security_group_ids = [aws_security_group.private-allow.id]

  tags = {
    Name = "private-instance"
  }
}