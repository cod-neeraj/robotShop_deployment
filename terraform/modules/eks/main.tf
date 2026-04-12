resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.eks_cluster_arn


  vpc_config {
    subnet_ids = var.private_subnet_ids
    
    endpoint_private_access = true
    endpoint_public_access  = true
  }


}


resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = var.node_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = [var.node_instance_type]

  ami_type = "AL2023_x86_64_STANDARD"
  capacity_type = "ON_DEMAND"


}