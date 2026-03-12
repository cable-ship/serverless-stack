variable "vpc_name" {
  description = "Name of the VPC."
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "List of availability zones (must match length of subnet lists)."
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks."
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks."
  type        = list(string)
  default     = []
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "Tenancy of instances (default or dedicated)."
  type        = string
  default     = "default"
}

variable "map_public_ip_on_launch" {
  description = "Map public IP on launch for public subnets."
  type        = bool
  default     = true
}

variable "public_subnet_suffix" {
  description = "Suffix for public subnet names."
  type        = string
  default     = "public"
}

variable "private_subnet_suffix" {
  description = "Suffix for private subnet names."
  type        = string
  default     = "private"
}

variable "create_igw" {
  description = "Create Internet Gateway and public route table."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets."
  type        = bool
  default     = true
}

variable "create_vpc_endpoints" {
  description = "Create VPC endpoints (e.g. CloudWatch Logs for ECS)."
  type        = bool
  default     = true
}

variable "vpc_endpoint_security_group_description" {
  description = "Description for VPC endpoint security group."
  type        = string
  default     = "Allow HTTPS from VPC for VPC endpoints"
}

variable "vpc_endpoint_private_dns_enabled" {
  description = "Enable private DNS for VPC endpoints."
  type        = bool
  default     = true
}

variable "vpc_endpoint_sg_ingress_from_port" {
  description = "VPC endpoint SG ingress from_port."
  type        = number
  default     = 443
}

variable "vpc_endpoint_sg_ingress_to_port" {
  description = "VPC endpoint SG ingress to_port."
  type        = number
  default     = 443
}

variable "vpc_endpoint_sg_ingress_protocol" {
  description = "VPC endpoint SG ingress protocol."
  type        = string
  default     = "tcp"
}

variable "vpc_endpoint_sg_ingress_cidr_blocks" {
  description = "VPC endpoint SG ingress CIDR blocks. Defaults to VPC CIDR when null."
  type        = list(string)
  default     = null
}

variable "vpc_endpoint_sg_ingress_description" {
  description = "VPC endpoint SG ingress rule description."
  type        = string
  default     = "HTTPS from VPC"
}

variable "vpc_endpoint_sg_egress_from_port" {
  description = "VPC endpoint SG egress from_port (0 for all)."
  type        = number
  default     = 0
}

variable "vpc_endpoint_sg_egress_to_port" {
  description = "VPC endpoint SG egress to_port (0 for all)."
  type        = number
  default     = 0
}

variable "vpc_endpoint_sg_egress_protocol" {
  description = "VPC endpoint SG egress protocol (-1 for all)."
  type        = string
  default     = "-1"
}

variable "vpc_endpoint_sg_egress_cidr_blocks" {
  description = "VPC endpoint SG egress CIDR blocks."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "region" {
  description = "AWS region (for VPC endpoint service names)."
  type        = string
}

variable "public_route_destination_cidr" {
  description = "Destination CIDR for public route (default route via IGW)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "private_route_destination_cidr" {
  description = "Destination CIDR for private route (via NAT Gateway)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "eip_domain" {
  description = "Domain for EIP (vpc or standard)."
  type        = string
  default     = "vpc"
}

variable "private_subnet_map_public_ip" {
  description = "Map public IP on launch for private subnets."
  type        = bool
  default     = false
}

variable "managed_by_tag" {
  description = "Value for ManagedBy tag."
  type        = string
  default     = "terraform"
}

variable "default_tags" {
  description = "Default tags merged before var.tags. When null, uses Environment and ManagedBy."
  type        = map(string)
  default     = null
}

variable "environment" {
  description = "Environment name for tagging."
  type        = string
}

variable "tags" {
  description = "Additional tags to merge onto all resources."
  type        = map(string)
  default     = {}
}
