output "eks_cluster_arn" {
    value = aws_iam_role.eks_cluster.arn
}

output "node_arn" {
    value = aws_iam_role.node.arn
}