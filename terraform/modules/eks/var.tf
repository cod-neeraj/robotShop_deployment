variable "cluster_name" {
  type = string
}

variable "eks_cluster_arn" {
   type = string
}

variable "node_arn" {
    type = string
}

variable "ebs_csi_arn" {
    type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_instance_type" {
  type = string
  default = "t3.medium"
}

variable "desired_size" {
  type = number
  default = 3
}

variable "max_size" {
  type = number
  default = 5
}

variable "min_size" {
  type = number
  default = 1
}