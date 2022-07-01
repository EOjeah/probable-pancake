provider "aws" {
  region  = "us-east-1"
  profile = "escrowdev"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_vpc" "devassoc-vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "devassoc-vpc"
  }
}

resource "aws_internet_gateway" "devassoc-igw" {
  vpc_id = aws_vpc.devassoc-vpc.id

  tags = {
    Name = "devassoc-igw"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id            = aws_vpc.devassoc-vpc.id
  cidr_block        = var.public-1-cidr
  availability_zone = var.atier-az

  tags = {
    Name = "public-1-subnet"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id            = aws_vpc.devassoc-vpc.id
  cidr_block        = var.public-2-cidr
  availability_zone = var.btier-az

  tags = {
    Name = "public-2-subnet"
  }
}

resource "aws_subnet" "private-1" {
  vpc_id            = aws_vpc.devassoc-vpc.id
  cidr_block        = var.private-1-cidr
  availability_zone = var.atier-az

  tags = {
    Name = "private-1-subnet"
  }
}

resource "aws_subnet" "private-2" {
  vpc_id            = aws_vpc.devassoc-vpc.id
  cidr_block        = var.private-2-cidr
  availability_zone = var.btier-az

  tags = {
    Name = "private-2-subnet"
  }
}

resource "aws_route_table" "devassoc-internet-rt" {
  vpc_id = aws_vpc.devassoc-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devassoc-igw.id
  }

  tags = {
    Name = "devassoc-rt"
  }
}

resource "aws_route_table" "devassoc-nat-rt" {
  vpc_id = aws_vpc.devassoc-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.devassoc-nat.id
  }

  tags = {
    Name = "devassoc-nat-rt"
  }
}

resource "aws_eip" "devassoc-eip" {
  vpc = true
}

resource "aws_nat_gateway" "devassoc-nat" {
  allocation_id = aws_eip.devassoc-eip.id
  subnet_id     = aws_subnet.public-2.id

  tags = {
    Name = "devassoc-nat"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.devassoc-igw]
}

# for private subnets 
resource "aws_route_table_association" "private-1-rta" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.devassoc-nat-rt.id
}

resource "aws_route_table_association" "private-2-rta" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.devassoc-nat-rt.id
}

resource "aws_route_table_association" "public-1-rta" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.devassoc-internet-rt.id
}

resource "aws_route_table_association" "public-2-rta" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.devassoc-internet-rt.id
}

resource "aws_security_group" "restricted-http-ssh-sg" {
  name        = "restricted-http-ssh"
  description = "HTTP and SSH from my IP address only"
  vpc_id      = aws_vpc.devassoc-vpc.id

  # ingress {
  #   description = "TLS from anywhere"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  # ingress {
  #   description = "TLS from VPC"
  #   from_port   = 81
  #   to_port     = 81
  #   protocol    = "tcp"
  #   cidr_blocks = [aws_vpc.webapp-vpc.cidr_block]
  # }

  ingress {
    description = "SSH from my PC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devassoc-sg-ssh-http"
  }
}

resource "aws_security_group" "open-http-ssh-sg" {
  name        = "open-http-ssh"
  description = "HTTP and SSH from Anywhere."
  vpc_id      = aws_vpc.devassoc-vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devassoc-open-ssh-http"
  }
}

resource "aws_key_pair" "devassoc-key" {
  key_name   = "devassoc-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCu6mAcAaZ4DDdUB9YZ66d4IurZUuPTye14hySC9FNd3rpeIFtja76dXU/Rdq0iV8eZEN0SKvE7movTG4oJohHeacUSAXramNLRQgF0DLNimW413bsdd4nbtzUxqNBzanLtcyASkaIaBkGRhglQfRfppNC+YaWFVrPNFVVRn0gVrKgQyAe1wFZgoyPFl4IXhAfqwIzgDpgOaXvvn4GnP0GHu+/eYZ3riZ5qTm1uiVAwmJsKL8aa1Ur+F53REtayOgC5EpnNRtluyzEIM/+yhubXw7aoufDqxdvTYp7CbM3vFjsAoNft5FRBbNsY0dHKHduCTKNsIzawog+iEfa/bobCOt/DSkoPvFfy7J88hefK3aUoP+UZJeeM886N3PaeTJyAT6w8FSzelRlkG9X+iY0fIaxyYQcAsrVTHCJtY//KRLYy5jJuWorWcExBn4ELVgaS4biwBuf/Mr9ujITj6sSB1/YuzPHMrk0OSx3bkS94WaflJDc7Dz1ClDTFPgKaTu0= chukky@Emmanuels-MacBook-Pro-2.local"
}

resource "aws_instance" "webserver-1" {
  ami                         = var.aws-ami
  instance_type               = "t2.micro"
  private_ip                  = lookup(var.private-ipa, "web1", "172.31.2.21")
  vpc_security_group_ids      = [aws_security_group.restricted-http-ssh-sg.id]
  subnet_id                   = aws_subnet.public-1.id
  key_name                    = "devassoc-key"
  associate_public_ip_address = "true"
  iam_instance_profile        = aws_iam_instance_profile.devassoc-instance-profile.name
  user_data                   = <<-EOT
  #!/bin/bash
  yum install httpd -y
  systemctl start httpd
  systemctl enable httpd
  EOT
  tags = {
    Name = "webserver"
  }

  depends_on = [aws_key_pair.devassoc-key, aws_iam_role.devassoc-webserver-role]
}

resource "aws_instance" "webserver-1-private" {
  ami                    = var.aws-ami
  instance_type          = "t2.micro"
  private_ip             = lookup(var.private-ipa, "app1", "172.31.101.21")
  vpc_security_group_ids = [aws_security_group.open-http-ssh-sg.id]
  subnet_id              = aws_subnet.private-1.id
  key_name               = "devassoc-key"
  iam_instance_profile   = aws_iam_instance_profile.devassoc-instance-profile.name
  user_data              = file("server-polly.txt")
  tags = {
    Name = "private-instance"
  }
}

resource "aws_iam_instance_profile" "devassoc-instance-profile" {
  name = "devassoc-instance-profile"
  role = aws_iam_role.devassoc-webserver-role.name
}

resource "aws_iam_role" "devassoc-webserver-role" {
  name = "devassoc-webserver-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "devassoc-polly-ro-policy-attachement" {
  role       = aws_iam_role.devassoc-webserver-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPollyReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "devassoc-translate-ro-policy-attachement" {
  role       = aws_iam_role.devassoc-webserver-role.name
  policy_arn = "arn:aws:iam::aws:policy/TranslateReadOnly"
}
