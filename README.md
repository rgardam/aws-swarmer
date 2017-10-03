# aws-swarmer
a Terraform module to deploy a fully functional docker swarm cluster

It utilises the aws systems manager shared resources parameter store to store the swarm join keys encrypted.

To deploy 

```make deploy-swarm```

To enable remote management of the docker swarm 

```make connect-docker-swarm```

To destroy all infrastructure 

```make teardown ```


TODO. 

- Use autoscaling groups to manage workers
- Handle multiple ssh users
- Make into a proper terraform module