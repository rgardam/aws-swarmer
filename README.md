# aws-swarmer
a Terraform module to deploy a fully functional docker swarm cluster

It utilises the aws systems manager shared resources parameter store to store the swarm join keys encrypted.

To deploy 

```make deploy-swarm```

To enable remote management of the docker swarm 

```make connect-docker-swarm```

```export DOCKER_HOST=tcp://127.0.0.1:2374```

To destroy all infrastructure 

```make teardown ```

BUGS. 
- There is currently an issue with docker swarm that is affecting the overlay network.
    - see https://github.com/moby/moby/issues/32195 for more information