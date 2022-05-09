# Terraform is looking for terraform.tfvars file and attaches it automatically
subnet_prefix = "10.0.200.0/24"
subnet_prefix_2 = ["10.0.1.0/24", "10.0.2.0/24"]

another_prefix = [{cidr_block = "10.0.1.0/24", name = "prod_subnet"}, {cidr_block = "10.0.2.0/24", name = "dev_subnet"}]