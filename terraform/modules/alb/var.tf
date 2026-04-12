variable "name" {
  description = "Name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_sg_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where ALB will be placed"
  type        = list(string)
}

variable "app_port" {
  description = "Backend application port"
  type        = number
  default     = 8080
}