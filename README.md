# OSGi Configuration Admin / Kubernetes Integration Prototype

[![CI Build](https://github.com/rotty3000/osgi-config-aff/actions/workflows/build.yml/badge.svg)](https://github.com/rotty3000/osgi-config-aff/actions/workflows/build.yml)

This project is an experiment to produce the smallest and fastest Docker image that contains a complete OSGi runtime focusing on OSGi Configuration Admin with *live*, volume mounted [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) and [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

Use ConfigMaps or Secrets files to mount [Apache Felix FileInstall](https://felix.apache.org/documentation/subprojects/apache-felix-file-install.html) compatible config (`.cfg|.config`) files to the `/app/configs` directory.

The [Apache Felix Interpolation plugin](https://github.com/apache/felix-dev/blob/master/configadmin-plugins/interpolation/README.md) is also configured to use the `/app/configs` directory and stands ready to replace placeholders found in your configurations with the values found there. The interpolation plugin also supports multiple directories using comma-separated syntax.

**Note** *You can dynamically install additional bundles by placing them into the `/app/configs` directory if you wish. But remember the JVM has been reduced using [jlink](https://docs.oracle.com/en/java/javase/17/docs/specs/man/jlink.html). So the dependencies of certain bundles may not be satisfied by parts of the JDK that have been omitted, resulting in them not resolving.*

## Basic Use

Start the container using a basic invocation:

```
docker run --pull rotty3000/config-osgi-k8s-demo:latest
```

## Build the Docker image

To build the image, execute:

```bash
docker build --pull --rm -f Dockerfile -t config-osgi-k8s-demo .
```

### Run the image (with local gogo shell access)

To run the container with gogo shell access expose port 11311:

```bash
docker run \
	-it -p 11311:11311 \
	--rm --name config-osgi-k8s-demo \
	config-osgi-k8s-demo:latest
```

You can connect with a telnet client from localhost:

```bash
]$ telnet localhost 11311
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
g!
```

## Logging

The container contains the OSGi Log Service (1.4) with Logback & SLF4J API which is configured using a default `logback.xml` which can be overridden by a ConfigMap at `/app/log/logback.xml`.

Here's a more thorough run example using the sample files in the local `configs` directory and the `logback.xml` that turns up the configuration infra log levels.

```bash
docker run \
	-it -p 11311:11311 \
	--rm --name config-osgi-k8s-demo \
	-v "$(pwd)/logback.xml:/app/log/logback.xml" \
	-v "$(pwd)/configs:/app/configs" \
	config-osgi-k8s-demo:latest
```

Edit the config files to observe live updates.

### Debugging/Tuning the JVM

The `JAVA_OPTS` environment variable is ready for passing JVM options for either debugging or tuning purposes.

To enable debugging you have to:

* pass appropriate `JAVA_OPTS` environment variable which enable debugging
* expose the port you defined for debugging (here `8000`)

Here's a local invocation using the docker run command:

```bash
docker run \
	-it -p 11311:11311 -p 8000:8000 \
	--rm --name config-osgi-k8s-demo \
	-v "$(pwd)/configs:/app/configs" \
	-v "$(pwd)/logback.xml:/app/log/logback.xml" \
	-e JAVA_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=*:8000" \
	config-osgi-k8s-demo
```

### Minikube (Optional)

_If you wish to use the image in Minikube, make sure to execute the following in the same terminal before building._

```bash
eval $(minikube docker-env)
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
	- image: config-osgi-k8s-demo
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
		mountPath: "/app/configs" # Mount it this path
		readOnly: true
	  - name: logback-config
		mountPath: "/app/log"
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
