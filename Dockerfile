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

RUN \
	apk add curl tar perl-xml-twig tree && \
	mkdir -p /app/bin && \
	curl https://maven.apache.org/xsd/maven-4.0.0.xsd -o /app/bin/maven-4.0.0.xsd && \
	curl https://downloads.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz -o /app/bin/apache-maven-3.8.4-bin.tar.gz && \
	tar -xf /app/bin/apache-maven-3.8.4-bin.tar.gz --directory /app/bin/ && \
	mv /app/bin/apache-maven-3.8.4 /app/bin/maven

COPY pom.xml base.bndrun exec.bndrun LICENSE /app/bin/

RUN \
	tree -h /app &&\
	MAIN_MODULE=$(xml_grep --text_only '/project/artifactId' /app/bin/pom.xml) && \
	MODULES=${MAIN_MODULE},jdk.jdwp.agent && \
	echo "MODULES: ${MODULES}" && \
	/app/bin/maven/bin/mvn -f /app/bin/ -ntp verify && \
	$JAVA_HOME/bin/jlink \
		--no-header-files \
		--no-man-pages \
		--compress=2 \
		--add-modules ${MODULES} \
		--module-path /app/bin/target/ \
		--launcher start=${MAIN_MODULE} \
		--output /app/jre

COPY start /app/jre/bin/start

RUN \
	rm -rf /app/bin && \
	tree -h /app && \
	cat /app/jre/bin/start

FROM alpine:3

ENV JAVA_OPTS=-XX:+UseZGC

RUN \
	apk --no-cache add tini && \
	addgroup -g 1000 appuser && \
	adduser -u 1000 -G appuser -s /bin/false -D appuser

COPY --from=build --chown=appuser:appuser /app /app

WORKDIR /app/jre/bin

USER appuser

ENTRYPOINT [\
	"/sbin/tini", \
	"/app/jre/bin/start" \
]
