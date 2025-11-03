# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/20"

  tags = {
    Name = "TempVPC"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.0.0/22"
  map_public_ip_on_launch = true   # dă IP public instanțelor din acest subnet
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "Public-Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.4.0/22"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "Private-Subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "Main-Internet-Gateway"
  }
}

# Route Table pentru subnetul public
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"          # Tot traficul
    gateway_id = aws_internet_gateway.igw.id  # Merge prin Internet Gateway
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# Asociere între public subnet și route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # SSH de oriunde (atenție la securitate)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # HTTP de oriunde
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # HTTPS de oriunde
  }

  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # adding 30080 port for k3s
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]   # Tot traficul de ieșire permis
  }
}

variable "ssh_public_key" {
  type = string
}

#cheia privata pt conectare ssh la ec2 ubuntu
resource "aws_key_pair" "my_key" {
  key_name   = "my-ssh-key"
  public_key = var.ssh_public_key
}

#ia ultima versiune de ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Ubuntu
resource "aws_instance" "ubuntu_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name               = aws_key_pair.my_key.key_name

  tags = {
    Name = "Ubuntu-Public"
  }
}

# Generează un sufix aleator pentru numele bucket-ului
resource "random_id" "suffix" {
  byte_length = 4
}

# Creează bucket-ul S3 fără acl (argumentul acl e deprecated)
resource "aws_s3_bucket" "dummy_bucket" {
  bucket = "terraform-test-bucket-${random_id.suffix.hex}"
}