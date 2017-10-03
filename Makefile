manager_address=$(shell terraform output bootstrapped_instance_dns)

deploy-swarm: 
	terraform init
	terraform plan 
	terraform apply

connect-docker-swarm:
	@ssh -NL localhost:2374:/var/run/docker.sock docker@$(manager_address) -o StrictHostKeyChecking=no &
	@export DOCKER_HOST=tcp://127.0.0.1:2374

teardown: 
	terraform destroy