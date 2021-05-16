## Kubernetes Notes

### stream logs from all pods with label

```
kubectl logs -f -l app=osgi-config
```

```
kubectl logs deployment/osgi-config-deployment-demo -f --tail=50
```