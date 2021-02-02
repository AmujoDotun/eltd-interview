provider "aws" {
  region = "us-east-2"
  access_key = "AKIAINBIW4LHGDVKKM7A"
  secret_key = "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"
}

# resource "aws_instance" "eltd-server" {
#     ami = "ami-0dd9f0e7df0f0a138"
#     instance_type = "t2.micro"

#     tags = {
#       "Name" = "Ubuntu-Server"
#     }

  
# }



resource "aws_vpc" "eltd-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      "Name" = "interview"
    }
  
}



resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.eltd-vpc.id

}

# 3. Create Custom Route Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.eltd-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}


# 4. Create a Subnet
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.eltd-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    "Name" = "prod-subnet"
  }
}

# 5. Associate subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create Security Group to allow port 22,80,443

resource "aws_security_group" "allow-web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.eltd-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_WEB"
  }
}

# 7. Create a network interface with an ip oin the subnet that was created in steop4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web.id]

}

# 8. assign an elastiv IpO to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

# 9. create Ubuntu server and install/enablke apache2

resource "aws_instance" "web-server-instance" {
  ami = "ami-0dd9f0e7df0f0a138"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "first-keypair"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo Hello, This is the interview task, by Samuel 🙂 > /var/www/html/index.html'
            EOF

    tags = {
      "Name" = "Web-server"
    }
}