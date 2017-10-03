output "bootstrapped_instance_dns" {
  value = "${aws_instance.bootstrap_manager.public_dns}"
}

output "managers_instance_dns" {
  value = ["${aws_instance.additional_managers.*.public_dns}"]
}

output "workers_instance_dns" {
  value = ["${aws_instance.workers.*.public_dns}"]
}
