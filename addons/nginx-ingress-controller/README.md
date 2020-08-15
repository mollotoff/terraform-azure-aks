# Nginx Ingress Controller with AWS NLB

Source: https://aws.amazon.com/de/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/

```bash
k apply -f nginx-ingress-controller.yaml
k apply -f nlb-service.yaml
k get svc -A
k apply -f apple.yaml
k apply -f banana.yaml
# adapt the domain name
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=kubernauts.de/O=kubernauts.de"
k create secret tls tls-secret --key tls.key --cert tls.crt
# adapt the domain name in example-ingress.yaml
k apply -f example-ingress.yaml
# in Route53 create a subdomain fruits.kubernauts.de and point it to the NLB (CNAME)
curl  https://fruits.kubernauts.de/apple -k
curl  https://fruits.kubernauts.de.de/banana -k
```
