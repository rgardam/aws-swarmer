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

TODO. 
- Handle multiple ssh users

BUGS. 
- There is currently an issue with routing a HTTP ELB. 
    * It appears that when a HTTP ELB is used with a container listening on the same port the request takes up to 30 seconds. 
    * Switching to a TCP ELB resolves this issue. It would mean that a nginx container is needed to terminate http requests.