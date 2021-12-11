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

ARG BASE_DIR
ARG START_SCRIPT=start
ARG EXTRA_MODULES=jdk.jdwp.agent
ARG PRINT_JDEPS

COPY $BASE_DIR /app/bin

RUN \
	if [ "${BASE_DIR}x" = "x" ];then \
		echo ">>>>>> Need to pass --build-arg BASE_DIR=<value>"; exit 1; \
	else \
		echo ">>>>>> BASE_DIR=${BASE_DIR}"; \
	fi && \
	if [ ! -f /app/bin/$START_SCRIPT ];then \
		echo ">>>>>> /app/bin/$START_SCRIPT does not exist. Pass --build-arg START_SCRIPT=<value> relative to BASE_DIR argument"; \
		exit 1; \
	else \
		echo ">>>>>> START_SCRIPT=${START_SCRIPT}"; \
	fi && \
	apk add unzip tree && \
	mkdir -p /tmp/packages && \
	(cd /app/bin && find . -type f -not -iname '*.jar' -exec cp --parents '{}' '/tmp/packages/' ';') && \
	for i in $(find /app/bin/ -type f -iname '*.jar' -print);do unzip -q -o $i -d /tmp/packages -x module-info.class META-INF/\* OSGI-INF/\* OSGI-OPT/\* 2> /dev/null;done && \
	if [ "${PRINT_JDEPS}x" != "x" ];then $JAVA_HOME/bin/jdeps -verbose:class --ignore-missing-deps --recursive /tmp/packages/;fi && \
	MODULES=`$JAVA_HOME/bin/jdeps --print-module-deps --ignore-missing-deps --recursive /tmp/packages/ | tail -1` && \
	MODULES=${MODULES}${EXTRA_MODULES:+,${EXTRA_MODULES}} && \
	echo "Calculated JDK MODULES: ${MODULES}" && \
	$JAVA_HOME/bin/jlink --no-header-files --no-man-pages --add-modules ${MODULES} --compress=2 --output /app/jre && \
	mv /app/bin/${START_SCRIPT} /app/bin/start && \
	chmod +x /app/bin/start

RUN tree -h /app

FROM alpine:3

ARG CLASSPATH=.:jar/*
ENV CLASSPATH=${CLASSPATH}
ENV JAVA_OPTS=-XX:+UseZGC

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
