# config-osgi-k8s-demo

## OSGi Conguration Admin / Kubernetes Integration Prototype

[![CI Build](https://github.com/rotty3000/osgi-config-aff/actions/workflows/maven.yml/badge.svg)](https://github.com/rotty3000/osgi-config-aff/actions/workflows/maven.yml)

This project produces a Docker image that contains a complete prototype integrating OSGi Configuration Admin with *live*, volume mounted [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) and [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

Use ConfigMap or Secret files to mount [Apache Felix FileInstall](https://felix.apache.org/documentation/subprojects/apache-felix-file-install.html) compatible config (`.cfg|.config`) files to the `/mnt/configs` directory *(or to another directory... if you like, just remember to override the defaults set in the Dockerfile).*

The [Apache Felix Interpolation plugin](https://github.com/apache/felix-dev/blob/master/configadmin-plugins/interpolation/README.md) is also configured by default with the `/mnt/configs` directory and ready to replace placeholders found in your configurations with the Secrets found there.

The interpolation plugin in this setup supports multiple directories using comma-separated syntax to accomodate multiple Secrets directory mounts.

*FYI* You can even install bundles by placing them into the `/mnt/configs` directory if you wish.

### Basic Use

Start the container using the most basic invocation:

```
docker run -it rotty3000/config-osgi-k8s-demo:latest
```

### Logging

There's a complete OSGi Log Service (1.4) & slf4j logging setup with a default `logback.xml` which can be overriden by a ConfigMap at `/mnt/logback/logback.xml`.

### GOGO Telnet shell

There's a telnet client present so if you `exec` into the container you can connect to it

```bash
docker exec -it rotty3000/config-osgi-k8s-demo:latest telnet localhost 11311
```

Here's a more thorough example using the sample files in the local `configs` directory and the `logback.xml` that turns up the configuration infra log levels.

```bash
docker run -it \
	--rm --name config-osgi-k8s-demo \
	-v "$(pwd)/logback.xml:/mnt/logback/logback.xml" \
	-v "$(pwd)/configs:/mnt/configs" \
	rotty3000/config-osgi-k8s-demo:latest
```

### Easy System Properties

Any environment variables that start with `-D` will be added to the Java command on startup.

### DEBUG

The `JAVA_OPTS` environent varialbe is ready for passing JVM options, like debugging:

```bash
docker run \
	-it \ # run interactively
	-p 8000:8000 \ # open port 8000 for host debugging
	--rm \ # remove any existing containers (just for testing)
	--name config-osgi-k8s-demo \ # call it what you want...
	-v "$(pwd)/mnt/configs:/mnt/configs" \ # mount the sample scan directory
	-e JAVA_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=*:8000" \ # debug
	rotty3000/config-osgi-k8s-demo:latest
```

## Build docker image

If you wish to use the image in minikube, make sure to execute the following in the same terminal before building.

```bash
eval $(minikube docker-env)
```

To build the image, execute:

```bash
docker build --pull --rm -f "Dockerfile" \
	-t rotty3000/config-osgi-k8s-demo \
	"."
```

## ConfigMap Example

Consider the following Kubernetes Config Map:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: osgi-configmap-demo
data:
  # property-like keys; each key maps to a simple value
  player_initial_lives: "3"

  # FileInstall Config Files
  game.pid.config: |
    player.initial.lives="$[env:player_initial_lives]"
    player.maximum-lives="5"
```

Now let's consider the following Pod definition:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: osgi-configmap-demo-pod
spec:
  containers:
    - image: rotty3000/config-osgi-k8s-demo
      name: osgi-configmap-demo-pod-demo
      imagePullPolicy: Never
      resources:
        limits:
          cpu: "250m"
          memory: "128Mi"
      env:
        # Define an environment variable
        - name: player_initial_lives
          valueFrom:
            configMapKeyRef:
              name: osgi-configmap-demo # The ConfigMap this value comes from.
              key: player_initial_lives # The key to fetch.
      volumeMounts:
      - name: osgi-config         # Mount the volume with this name
        mountPath: "/mnt/configs" # Mount it this path
        readOnly: true
      - name: logback-config
        mountPath: "/mnt/logback"
        readOnly: true
  volumes:
    # You set volumes at the Pod level, then mount them into containers inside that Pod
    - name: osgi-config
      configMap:
        # Provide the name of the ConfigMap you want to mount.
        name: osgi-configmap-demo
        # An array of keys from the ConfigMap to create as files
        # These are the OSGi FileInstall configuration files to be mounted
        items:
        - key: "game.pid.config"
          path: "game.pid.config"
    - name: logback-config
      configMap:
        name: logback-configmap-demo
        items:
        - key: "logback.xml"
          path: "logback.xml"
```

#### Notes

Get *processed* configuration properties
```
g! sr = servicereference org.osgi.service.cm.ConfigurationAdmin

g! (getconfiguration "game.pid") processedproperties $sr
```