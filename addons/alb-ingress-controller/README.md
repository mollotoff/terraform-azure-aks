# ALB Ingress Controller Deployment

Adapt the `cluster-name` in `alb-ingress-controller.yaml`:

```bash
- --cluster-name=docker-eks-spot 
```

and apply both yaml files.

```bash
k apply -f rbac-role.yaml
k apply -f alb-ingress-controller.yaml
```

For testing please refer to:

https://eksworkshop.com/beginner/130_exposing-service/ingress_controller_alb/

https://github.com/kubernetes-sigs/aws-alb-ingress-controller/tree/master/docs/examples