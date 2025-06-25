# Create a VPC
resource "aws_vpc" "SOC2_VPC" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "SOC2_VPC"
  }
}

# Create Public Subnet 1 (attach VPC, CIDR block and AZ1)
resource "aws_subnet" "SOC2_PubSN1" {
  vpc_id            = aws_vpc.SOC2_VPC.id
  cidr_block        = var.pub1_cidr
  availability_zone = var.az1

  tags = {
    Name = "SOC2_PubSN1"
  }
}

# Create Public Subnet 2 (attach VPC, CIDR block and AZ2)
resource "aws_subnet" "SOC2_Pub_SN2" {
  vpc_id            = aws_vpc.SOC2_VPC.id
  cidr_block        = var.pub2_cidr
  availability_zone = var.az2

  tags = {
    Name = "SOC2_Pub_SN2"
  }
}

# Create Internet Gateway (attach to vpc)
resource "aws_internet_gateway" "SOC2_IGW" {
  vpc_id = aws_vpc.SOC2_VPC.id

  tags = {
    Name = "SOC2_IGW"
  }
}

# Route Tables
# Create Public Route Table (attach vpc, allow all possible IPV4 addresses, route traffic to internet gateway)
resource "aws_route_table" "SOC2_RT_Pub" {
  vpc_id = aws_vpc.SOC2_VPC.id

  route {
    cidr_block = var.all_cidr
    gateway_id = aws_internet_gateway.SOC2_IGW.id
  }

  tags = {
    Name = "SOC2_RT_Pub"
  }
}

# Route Tables Associations
# Create Route Table Association for public subnet 1(attach public subnet 1 and associate to public route table)
resource "aws_route_table_association" "SOC2_RT_Pub1_Assoc1" {
  subnet_id      = aws_subnet.SOC2_PubSN1.id
  route_table_id = aws_route_table.SOC2_RT_Pub.id
}

# Create Route Table Association for public subnet 2(attach public subnet 2 and associate to public route table)
resource "aws_route_table_association" "SOC2_RT_Pub1_Assoc2" {
  subnet_id      = aws_subnet.SOC2_Pub_SN2.id
  route_table_id = aws_route_table.SOC2_RT_Pub.id
}

# Create K8S Security Group
resource "aws_security_group" "SOC2_SG" {
  name        = "SOC2_SG"
  description = "K8S_SG"
  vpc_id      = aws_vpc.SOC2_VPC.id

  ingress {
    description = "Allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_cidr]
  }

  tags = {
    Name = "K8S_SOC2_SG"
  }
}

#Create a Keypair
resource "aws_key_pair" "kubenetes-key" {
  key_name   = var.keyname
  public_key = file(var.kubenetes-key)
}

#Create Master node
resource "aws_instance" "Master_node" {
  count = 3  
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.SOC2_PubSN1.id
  availability_zone           = var.az1
  vpc_security_group_ids      = [aws_security_group.SOC2_SG.id]
  key_name                    = var.keyname
  associate_public_ip_address = true
  tags = {
      Name = "Master_node10${count.index}"
        }
}

resource "aws_instance" "Kubenetes-Ansible-Server" {
  ami                         = var.ami
  instance_type               = var.instance_type
  availability_zone           = var.az1
  key_name                    = var.keyname
  subnet_id                   = aws_subnet.SOC2_PubSN1.id
  vpc_security_group_ids      = [aws_security_group.SOC2_SG.id]
  associate_public_ip_address = true

  connection {  
      type        = "ssh" 
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("~/keypairs/kubenetes-key")
    }  
  provisioner "file" {
    source      = "~/keypairs/kubenetes-key"
    destination = "/home/ubuntu/kubenetes-key" 
  }
  provisioner "file" {
      source = "~/myproject/kubernetes_project/yml"
      destination = "/home/ubuntu/yml"    
  }
  provisioner "remote-exec" {
      inline = [
        "sudo apt-get update -y",
        "sudo apt-get install software-properties-common -y",
        "sudo add-apt-repository --yes --update ppa:ansible/ansible", 
        "sudo apt-get install ansible -y", 
        "sudo chmod 400 /home/ubuntu/kubenetes-key",
        "sudo mkdir /etc/ansible", 
        "sudo touch /etc/ansible/hosts",
        "sudo chown ubuntu:ubuntu /etc/ansible/hosts",
        "sudo bash -c ' echo \"StrictHostKeyChecking No\" >> /etc/ssh/ssh_config'",
        "sudo echo \"[Master]\" >> /etc/ansible/hosts",
        "sudo echo \"${data.aws_instance.Master_IP_address[0].public_ip} ansible_ssh_private_key_file=/home/ubuntu/kubenetes-key\" >> /etc/ansible/hosts",
        "sudo echo \"[Workers]\" >> /etc/ansible/hosts",
        "sudo echo \"${data.aws_instance.Master_IP_address[1].public_ip} ansible_ssh_private_key_file=/home/ubuntu/kubenetes-key\" >> /etc/ansible/hosts",
        "sudo echo \"${data.aws_instance.Master_IP_address[2].public_ip} ansible_ssh_private_key_file=/home/ubuntu/kubenetes-key\" >> /etc/ansible/hosts",
        "ansible -m ping all",
        "ansible-playbook -i /etc/ansible/hosts yml/user.yml",
        "ansible-playbook -i /etc/ansible/hosts yml/installation.yml",
        "ansible-playbook -i /etc/ansible/hosts yml/cluster.yml",
        "ansible-playbook -i /etc/ansible/hosts yml/join_master.yml",
        "ansible-playbook -i /etc/ansible/hosts yml/deployment.yml",
        "echo application runs on port 30001",
        "ansible-playbook -i /etc/ansible/hosts yml/monitoring.yml",
        "echo Promtheus runs on port 31090 and Grafana runs on port 31300"      
      ]
  }  
  tags = {
    Name = "Kubenetes-Ansible-Server6"
  }
}

data "aws_instance" "Master_IP_address" {
  count = 3
  filter {
    name   = "tag:Name"
    values = ["Master_node10${count.index}"]
  }
  depends_on = [
    aws_instance.Master_node,
  ]
}