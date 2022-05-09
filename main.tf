# https://www.youtube.com/watch?v=SLB_c_ayRMo

# AUTHORIZATION
#
provider "aws" {
  region = "us-east-1"
  # access_key = "access key"
  # decret_key = "Secret key"
}


# SAMPLE RESOURCE CODE BLOCK
#
# resource "<provider>_<resource_type>" "name" {
#   # config options ....
#   # sensitive_content = ""
#   # filename             = "${path.module}/files/outputfile"
#   # file_permission      = 0777
#   # directory_permission = 0777
# }
#
# name will not effect the aws
# ami image name can be different for different regions
resource "aws_instance" "my-first-serever" {
  ami                   = "ami-085925f297f89fce1"
  instance_type         = "t2.micro"
}

# PRACTICE
# Create key-pair in AWS/EC/keypairs in left side menu
# Create vpc   google: terraform aws vpc

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tag = {
    Name = "production"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vps.id
}

# Create a cutom Routes Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.default.id

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

# Create a subnet

variable "subnet_prefix" {
  description = "cidr block for the subnet"
  #default = "10.0.0.0/16"   // the default value if the value is not passed
  #type = any   #Supports number strings booleans maps sets objects tuples any
}
# Terraform will ask to assign the variable value when apply command starts 

variable "subnet_prefix_2" {
  description = "cidr block for the subnet 2"
  #default = "10.0.0.0/16"   // the default value if the value is not passed
  #type = any   #Supports number strings booleans maps sets objects tuples any
}

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vps.id
  cidr_block = var.another_prefix[0].cidr_block  #using a variable
  availabiliti_zone = "us-east-1a"
  tags = {
    Name = var.another_prefix[0].name
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id = aws_vpc.prod-vps.id
  cidr_block = var.another_prefix[1].cidr_block  #using a variable
  availabiliti_zone = "us-east-1a"
  tags = {
    Name = var.another_prefix[1].name
  }
}



# Assosiate Subnet with Route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# Create a security group to allow ports 22, 80, 443

resource "aws_security_group" "allow_web" {
  name        = "allow_webtraffic"
  description = "Allow Web traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [0.0.0.0/0]
    ipv6_cidr_blocks = [::/0]
  }

  ingress {
    description      = "HTTP traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [0.0.0.0/0]
    ipv6_cidr_blocks = [::/0]
  }

  ingress {
    description      = "SSH traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [0.0.0.0/0]
    ipv6_cidr_blocks = [::/0]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" //Any protocol
    cidr_blocks      = ["0.0.0.0/0"] //Any IP
    ipv6_cidr_blocks = ["::/0"] // Any IP
  }

  tags = {
    Name = "allow_web"
  }
}

# Create Network Interface

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# Assign an elastic IP to the network interface

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depend_on = [aws_internet_gateway.gw]
}

# Will print out the variable you need when apply command finished
output "server_public_ip" {
  value = aws_eip.one.server_public_ip
}

# Create UBUNTU server install/start apache

resource "aws_instance" "web-server-instance" {
  ami = "ami-085925f297f89fce1"
  instance_type = "t2.micro"
  availabiliti_zone = "us-east-1a"
  key_name = "main-key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web-server"
  }
}

output "server_private_ip" {
  value = aws_instance.web-server-instance.private_ip
}

output "server_id" {
  value = aws_instance.web-server-instance.id
}


# terraform init                              // Download the provider (providers) plugins

# terraform plan                              // Show what is going to happen once applied

# terraform apply                             // Start applying everything process
# =//= -target aws_resourse.resource_name     // Apply a specific resource
# =//= -var <"varName = varValue">            // Apply with a value for a declared variable set with CLI
# =//= -var-file varFileName.tfvars           // Apply and attach the custom vars file (terraform.tfvars is attached by default if exists)


# terraform destroy                           // Destroy all the infrastructure, resource will be terminated and deleted 
                                              // from AWS in 2 hours

# =//= -target aws_resourse.resource_name     // Destroy a specific resource< comment out the code block does the same

# terraform state list                        // Show all the resources in the current state
# terrafirm state show <resource>             // Show the specific resource current state with values

# terraform refresh                           // Refresh the current state, show output (close to apply, but does not do actions)

