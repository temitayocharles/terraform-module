output "jenkins_instance_profile_name" {
  value = length(aws_iam_instance_profile.jenkins_k8s_master) > 0 ? aws_iam_instance_profile.jenkins_k8s_master[0].name : lookup(var.iam_config.names, "jenkins_profile_name", "")
}

output "k8s_worker_instance_profile_name" {
  value = length(aws_iam_instance_profile.k8s_worker) > 0 ? aws_iam_instance_profile.k8s_worker[0].name : lookup(var.iam_config.names, "worker_profile_name", "")
}

output "roles" {
  value = {
    jenkins = length(aws_iam_role.jenkins_k8s_master) > 0 ? aws_iam_role.jenkins_k8s_master[0].arn : ""
    worker  = length(aws_iam_role.k8s_worker) > 0 ? aws_iam_role.k8s_worker[0].arn : ""
  }
}
