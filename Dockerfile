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

FROM azul/zulu-openjdk-alpine:11 AS build

RUN mkdir -p \
	/app/bin \
	/app/configs \
	/app/log

COPY target/exec.jar /app/exec.jar
COPY default-logback.xml /app/log/logback.xml

RUN \
	apk add unzip tree && \
	unzip /app/exec.jar -d /app/bin && \
	rm /app/exec.jar /app/bin/start /app/bin/start.bat && \
	rm -rf /app/bin/META-INF /app/bin/OSGI-OPT && \
	MODULES=`$JAVA_HOME/bin/jdeps --print-module-deps --ignore-missing-deps --recursive --module-path /app/bin/jar/ /app/bin/jar/*.jar | tail -1` && \
	$JAVA_HOME/bin/jlink --add-modules $MODULES,jdk.unsupported,jdk.jdwp.agent --compress=2 --output /app/jre

RUN \
	echo -e '#!/bin/sh\n\
LIB=/app/bin/jar\n\
CLASSPATH=$(find $LIB -type f -maxdepth 1 -exec echo -n {}: \;)\n\
JAVA_CMD="java ${JAVA_OPTS} --class-path ${CLASSPATH} aQute.launcher.Launcher $@"\n\
echo -e "=====\\nEXEC: ${JAVA_CMD}\\n====="\n\
${JAVA_CMD}' >> /app/bin/start && \
	chmod +x /app/bin/start

RUN tree /app

FROM alpine:3

RUN \
	apk --no-cache add dumb-init busybox-extras tree && \
	adduser -s /bin/false -D appuser

COPY --from=build --chown=appuser:appuser /app /app

ENV PATH=/app/jre/bin:$PATH

WORKDIR /app/bin

USER appuser

ENTRYPOINT ["dumb-init", "/app/bin/start"]
