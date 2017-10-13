
# Create Nginx Ingress Controller with SSL

Resources:
 * https://github.com/kubernetes/ingress-nginx#https
 * https://github.com/kubernetes/ingress-nginx/blob/master/examples/tls-termination/nginx/nginx-tls-ingress.yaml


## Commands

Create cluster:
```
./setup_cluster_with_ssl.sh test-ssl
```

Check that all the parts were made:
```
$ kubectl get secrets
NAME                  TYPE                                  DATA      AGE
default-token-52t1v   kubernetes.io/service-account-token   3         20m
tls-secret            kubernetes.io/tls                     2         16m
```
```
$ kubectl get pod
NAME                                READY     STATUS    RESTARTS   AGE
demo-echo-service-861424567-v71bd   1/1       Running   0          5m
```
```
$ kubectl -n kube-system get pod
NAME                                                     READY     STATUS    RESTARTS   AGE
default-http-backend-726995137-grwm4                     1/1       Running   0          17m
event-exporter-1421584133-f7p2j                          2/2       Running   0          24m
fluentd-gcp-v2.0-qzmhr                                   2/2       Running   0          24m
heapster-v1.4.2-305774564-25351                          3/3       Running   0          22m
kube-dns-3468831164-9zh8s                                3/3       Running   0          24m
kube-dns-autoscaler-244676396-4t9k9                      1/1       Running   0          24m
kube-proxy-gke-job-test-ssl-default-pool-da505488-c632   1/1       Running   0          24m
kubernetes-dashboard-1265873680-n8hsx                    1/1       Running   0          24m
nginx-ingress-controller-3457307997-ghkk0                1/1       Running   0          17m
```

The ingress might take a minute or two to setup. Once the address is populated, it is ready.
```
$  kubectl get ing
NAME               HOSTS     ADDRESS         PORTS     AGE
test-ssl-ingress   *         35.196.134.52   80, 443   4m
```

See what we get from curl:
```
$ curl -kv https://35.196.134.52
* Rebuilt URL to: https://35.196.134.52/
*   Trying 35.196.134.52...
* Connected to 35.196.134.52 (35.196.134.52) port 443 (#0)
* found 148 certificates in /etc/ssl/certs/ca-certificates.crt
* found 592 certificates in /etc/ssl/certs
* ALPN, offering http/1.1
* SSL connection using TLS1.2 / ECDHE_RSA_AES_128_GCM_SHA256
* 	 server certificate verification SKIPPED
* 	 server certificate status verification SKIPPED
* 	 common name: Kubernetes Ingress Controller Fake Certificate (does not match '35.196.134.52')
* 	 server certificate expiration date OK
* 	 server certificate activation date OK
* 	 certificate public key: RSA
* 	 certificate version: #3
* 	 subject: O=Acme Co,CN=Kubernetes Ingress Controller Fake Certificate
* 	 start date: Fri, 13 Oct 2017 16:40:13 GMT
* 	 expire date: Sat, 13 Oct 2018 16:40:13 GMT
* 	 issuer: O=Acme Co,CN=Kubernetes Ingress Controller Fake Certificate
* 	 compression: NULL
```

Note the line about `common name: Kubernetes Ingress Controller Fake Certificate (does not match '35.196.134.52')`.
That shows that we are using the default certs instead of our own.


## Debugging

Look at nginx.conf:
```
kubectl -n kube-system exec -it $(kubectl -n kube-system get pods | grep ingress | head -1 | cut -f 1 -d " ") -- cat /etc/nginx/nginx.conf | grep ssl_cert
```

Ingress Log:
```
kubectl -n kube-system log -f $(kubectl -n kube-system get pods | grep ingress | head -1 | cut -f 1 -d " ")
```
