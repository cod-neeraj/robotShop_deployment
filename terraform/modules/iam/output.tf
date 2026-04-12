output "eks_cluster_arn" {
    value = aws_iam_role.eks_cluster.arn
}

output "node_arn" {
    value = aws_iam_role.node.arn
}

output "ebs_csi_arn" {
  value = aws_iam_role.ebs_csi.arn
}