## Kubernetes Notes

### stream logs from all pods with label

```
kubectl logs -f -l app=osgi-config
```

```
kubectl logs deployment/osgi-config-deployment-demo -f --tail=50
```

### JLink

```
java --list-modules

$JAVA_HOME/bin/jdeps --print-module-deps --ignore-missing-deps --recursive jar/*.jar

MODULES=$($JAVA_HOME/bin/jdeps --print-module-deps --recursive jar/*.jar)

$JAVA_HOME/bin/jlink --add-modules $MODULES --output jlink
```

### Docker

Show image layer sizes

```
docker history <tag>
```

### Alpine Linux

Reduce image sizes:
- Add the `--no-cache` argument to `apk` calls to avoid storing the repo index (30+Mb)
- do `chown` during `COPY` operations