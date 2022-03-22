provider "aws" {
  access_key        = var.access_key
  secret_key        = var.secret_key
  region            = var.region
}

# 1 Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.subnet_prefix
  tags = {
    Name = "${var.resource_prefix}_vpc"
  }
}
# 2 Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}
# 3 Create Custom Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.resource_prefix}_${var.env_prefix_name}_gw"
  }
}
# 4 Create a Subnet
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_prefix
  availability_zone = var.availability_zone
  tags = {
    Name = "${var.resource_prefix}_${var.env_prefix_name}-subnet-1"
  }
}
# 5 Associate Subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.main_route_table.id
}
# 6 Create Securiry Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.resource_prefix}_${var.env_prefix_name}_allow_web_sg"
  }
}
# 7 Create a Network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = [var.private_ip]
  security_groups = [aws_security_group.allow_web.id]

  #   attachment {
  #     instance     = aws_instance.test.id
  #     device_index = 1
  #   }
}
# 8 Assign an elastic IP to the Network Interface Created in Step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = var.private_ip
  depends_on                = [aws_internet_gateway.gw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}
# 9 Create Ubuntu Server And Install Nginx 
resource "aws_instance" "web-server" {
  ami               = var.aim # eu-west-1
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  key_name          = var.ssh_key_name

  network_interface {
    network_interface_id = aws_network_interface.web-server-nic.id
    device_index         = 0
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install nginx -y
              sudo systemctl start nginx
              sudo bash -c "echo Hello web server initialized >> /var/www/html/index.html"
              sudo systemctl restart nginx
              EOF
  tags = {
    Name = "${var.resource_prefix}_${var.env_prefix_name} web server"
  }
}
