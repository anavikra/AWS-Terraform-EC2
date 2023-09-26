resource "aws_vpc" "nonprod_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name = "nonprod"
  }
}

resource "aws_subnet" "nonprod_public_subnet" {
  vpc_id                  = aws_vpc.nonprod_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "Nonprod-public"
  }

}

resource "aws_internet_gateway" "nonprod_internet_gateway" {
  vpc_id = aws_vpc.nonprod_vpc.id

  tags = {
    Name = "Nonprod-igw"
  }
}

resource "aws_route_table" "nonprod_public_rt" {
  vpc_id = aws_vpc.nonprod_vpc.id

  tags = {
    Name = "Nonprod-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.nonprod_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nonprod_internet_gateway.id

}

resource "aws_route_table_association" "nonprod_public_assoc" {
  subnet_id      = aws_subnet.nonprod_public_subnet.id
  route_table_id = aws_route_table.nonprod_public_rt.id
}

resource "aws_security_group" "nonprod_sg" {
  name        = "nonprod_sg"
  description = "nonprod security group"
  vpc_id      = aws_vpc.nonprod_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "nonprod_auth" {
  key_name   = "nonprodkey"
  public_key = file("~/.ssh/nonprodkey.pub")

}

resource "aws_instance" "Frontend-Web" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.nonprod_auth.id
  vpc_security_group_ids = [aws_security_group.nonprod_sg.id]
  subnet_id              = aws_subnet.nonprod_public_subnet.id
  user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 8
  }

  tags = {
    name = "nonprod-web"

  }

}
  