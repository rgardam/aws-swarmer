output "bootstrapped_instance_dns" {
  value = "${aws_instance.bootstrap_manager.public_dns}"
}

output "worker_elb_dns_name" {
  description = "DNS Name of the worker ELB"
  value       = "${module.elb.this_elb_dns_name}"
}

output "vpc_endpoint_s3_id" {
  description = "The ID of VPC endpoint for S3"
  value       = "${module.vpc.vpc_endpoint_s3_id}"
}