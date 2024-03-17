# variables
# Profile
variable "account_id" {
  description = ""
  type        = string
  sensitive   = true
}
variable "region" {
  description = ""
  type        = string
  default     = "us-east-1"
}

#RDS
variable "username" {
  description = "RDS Master username"
  type        = string
  sensitive   = true
}
variable "password" {
  description = "RDS Master password"
  type        = string
  sensitive   = true
}
variable "rds_name" {
  description = "RDS name"
  type        = string
  default     = ""
}


# VPC
variable "vpc_name" {
  description = "vpc name"
  type        = string
  default     = ""
}
variable "subnet_a_name" {
  description = "Subnet A name"
  type        = string
  default     = "public-instances"
}
variable "subnet_aa_name" {
  description = "Subnet A name"
  type        = string
  default     = "public-instances"
}
variable "subnet_b_name" {
  description = "Subnet b name"
  type        = string
  default     = "RDS"
}
variable "subnet_c_name" {
  description = "Subnet c name"
  type        = string
  default     = "RDS-secondary"
}


# S3
variable "bucket_name" {
  description = "s3 bucket name for the frontend app"
  type        = string
  default     = ""
}

#CodeBuild
variable "codebuild_role_name" {
  description = "name for the codebuild role"
  type        = string
  default     = ""
}
variable "codebuild_name" {
  description = "nmae for the codbuild app"
  type        = string
  default     = ""
}
variable "codebuild_description" {
  description = ""
  type        = string
  default     = ""
}

# ECR
variable "ecr_name" {
  description = "Repository name"
  type        = string
  default     = ""
}

# ECS
variable "task_port" {
  description = "Port to use for vikunja"
  type        = number
  default     = 3456
}
variable "image_name" {
  description = "Image to be used for the backend. This will be pulled for Vikunja API"
  type        = string
  default     = "" # the source is external to avoid dockerhub restrictions.
}


# Load Balancer
variable "lb-path" {
  description = " Load balancer path"
  type        = string
  default     = "/*"
}
