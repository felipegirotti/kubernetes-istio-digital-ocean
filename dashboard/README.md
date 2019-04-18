# Dashboard of your cluster
To install is simple, just run `./install.sh`

After that you can access by proxy: `kubectl proxy`     
It's create a proxy of your cluster, that way you can access by the URL: http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

For the authenticate you need create the token, run the command: `./get-token.sh` and copy the token output and use for login.  

More information: https://github.com/kubernetes/dashboard
