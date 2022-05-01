## Kubernetes Notes

### stream logs from all pods with label

```
kubectl logs -f -l app=osgi-config
```

```
kubectl logs deployment/osgi-config-deployment-demo -f --tail=50
```

### JLink

JLink a bnd executable jar that has JPMS metadata:

```bash
]$ $JAVA_HOME/bin/jlink \
	--no-header-files \
	--no-man-pages \
	--module-path target/exec.jar \
	--add-modules com.github.rotty3000.osgi.config.aff \
	--launcher start=com.github.rotty3000.osgi.config.aff \
	--output target/jlink
# For debugging add this line above
	--add-modules jdk.jdwp.agent \

]$ target/jlink/bin/java --list-modules
com.github.rotty3000.osgi.config.aff@0.0.1-SNAPSHOT open
java.base@17.0.3
java.instrument@17.0.3
java.logging@17.0.3
java.management@17.0.3
jdk.unsupported@17.0.3

]$ target/jlink/bin/java \
	-XX:+UseZGC \
	-Dfelix.fileinstall.dir=$(pwd)/configs \
	-Dorg.apache.felix.configadmin.plugin.interpolation.secretsdir=$(pwd)/configs \
	-m com.github.rotty3000.osgi.config.aff/aQute.launcher.pre.EmbeddedLauncher
```

#### Notes on JLink

```bash
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