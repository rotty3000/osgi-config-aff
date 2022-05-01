#    Licensed to the Apache Software Foundation (ASF) under one
#    or more contributor license agreements.  See the NOTICE file
#    distributed with this work for additional information
#    regarding copyright ownership.  The ASF licenses this file
#    to you under the Apache License, Version 2.0 (the
#    "License"); you may not use this file except in compliance
#    with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing,
#    software distributed under the License is distributed on an
#    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#    KIND, either express or implied.  See the License for the
#    specific language governing permissions and limitations
#    under the License.

FROM azul/zulu-openjdk-alpine:17 AS build

ARG EXECUTABLE_JAR
ARG MODULE_NAME
ARG EXTRA_MODULES

COPY $EXECUTABLE_JAR /tmp/$EXECUTABLE_JAR

RUN \
	mkdir -p /app/bin/ && \
	$JAVA_HOME/bin/jlink \
		--add-modules $MODULE_NAME${EXTRA_MODULES:+,$EXTRA_MODULES} \
		--compress=2 \
		--module-path /tmp/$EXECUTABLE_JAR \
		--no-header-files \
		--no-man-pages \
		--output /app/jre && \
	echo '#!/bin/sh' > /app/bin/start && \
	echo "JAVA_CMD=\"java \${JAVA_OPTS} -m $MODULE_NAME/aQute.launcher.pre.EmbeddedLauncher\"" >> /app/bin/start && \
	echo 'echo -e "=====\nEXEC: ${JAVA_CMD}\n====="' >> /app/bin/start && \
	echo '${JAVA_CMD} "$@"' >> /app/bin/start && \
	echo "### START SCRIPT ###" && \
	cat /app/bin/start && \
	echo "####################" && \
	chmod +x /app/bin/start && \
	/app/jre/bin/java --list-modules

FROM alpine:3

ENV JAVA_OPTS="${JAVA_OPTS:--XX:+UseZGC}"

RUN \
	apk --no-cache add tini && \
	adduser -s /bin/false -D appuser

COPY --from=build --chown=appuser:appuser /app /app

ENV PATH=/app/jre/bin:$PATH

WORKDIR /app/bin

USER appuser

ENTRYPOINT [\
	"/sbin/tini", \
	"/app/bin/start" \
]
