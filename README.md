# Example of Kubernetes and Istio(Basic)
For this example we are using the [Digital Ocean](https://www.digitalocean.com/) for managed kubernetes,    
but you are free to use Google, Azure, AWS, or even minikube(local).


For the Digital Ocean we are using the simple command bash to create cluster install istio and some resources (Mysql, RabbitMQ and the Dashboard).  
For that we need to expose the token to create the cluster via api. Please generate the token into the web console of Digital Ocean: https://cloud.digitalocean.com/account/api/tokens  
And now just export it in a enviroment variable `export DO_TOKEN={your_digital_ocean_token}`

Run the command `./bin/create-cluster.sh` (the command will create a clust with 3 nodes with 1vcpu and 2gb of memory).
It's takes some minutes, usually 3 or 5 minutes to prepare everthing for you, grab a :coffee:

The finally move the file of kubernetes config the output of script says to you, e.g:
`mv /tmp/kubernetes-file.conf ~/.kube/config`

## Dashboard
Access by proxy: `kubectl proxy`
It's create a proxy of your cluster, that way you can access by the URL: http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
For the authenticate you need create the token, run the command: `./dashboard/get-token.sh` and copy the token output and use for login. 

## Demo Apps
There 2 demo applications to deploy and tests
- Client [https://github.com/felipegirotti/spring-boot-event-driven-client-producer](https://github.com/felipegirotti/spring-boot-event-driven-client-producer)
- Place [https://github.com/felipegirotti/spring-boot-event-driven-producer](https://github.com/felipegirotti/spring-boot-event-driven-producer)

To deploy the demo apps it's simple:    
`kubectl apply -f ./app/client -f ./app/place`

To see the public url `kubectl get svc -l app=istio-ingressgateway -n istio-system`     
```
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                                                                                                                      AGE
istio-ingressgateway   LoadBalancer   10.245.11.222   104.248.111.9   15020:30682/TCP,80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:30482/TCP,15030:31907/TCP,15031:31941/TCP,15032:31102/TCP,15443:31835/TCP   2m
```

The **EXTERNAL-IP** is your url

### Testing
Added place: `curl -X POST -H "Content-Type: application/json" -d '{"client_id": 1, "name": "Test", "latitude": 10.22, "longitude": -12.223}'  http://104.248.111.9/api/v1/place`   
Get place: `curl http://104.248.111.9/api/v1/place/1`

Added Client: `curl -X POST -H "Content-Type: application/json" -d '{"name": "Client Test", "latitude": 10.22, "longitude": -12.223}'  http://104.248.111.9/api/v1/client`
List Clients: `curl http://104.248.111.9/api/v1/clients`

