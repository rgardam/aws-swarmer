output "sg_swarm" {
  value = "${aws_security_group.swarm.id}"
} 

output "bootstrapped_instance_dns" {
  value = "${aws_instance.bootstrap_manager.public_dns}"
}
 
output "manager_instance_dns" {
  value = "${aws_instance.additional_managers.public_dns}"
}

output "worker_instance_dns" {
  value = "${aws_instance.workers.public_dns}"
}