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

FROM azul/zulu-openjdk-alpine:11-jre-headless

RUN \
	adduser -s /bin/false -D appuser

RUN \
	mkdir /app && \
	mkdir /mnt/logback && \
	mkdir /mnt/configs

COPY target/osgi-config-exec.jar /app/osgi-config.jar
COPY default-logback.xml /mnt/logback/logback.xml

RUN \
	apk add bash unzip tree busybox-extras && \
	unzip /app/osgi-config.jar -d /app && \
	rm /app/osgi-config.jar /app/start.bat && \
	rm -rf /app/META-INF/maven /app/OSGI-OPT

COPY start /app/start

RUN \
	chmod +x /app/start && \
	chown -R appuser:appuser /app && \
	chown -R appuser:appuser /mnt/configs && \
	chown -R appuser:appuser /mnt/logback && \
	tree /app && \
	apk del unzip

ENV -Dfelix.cm.config.plugins=org.apache.felix.configadmin.plugin.interpolation
ENV -Dfelix.fileinstall.dir=/mnt/configs
ENV -Dfelix.fileinstall.log.level=4
ENV -Dgosh.args="--nointeractive -c telnetd -i 0.0.0.0 -p 11311 start"
ENV -Dlogback.configurationFile=file:/mnt/logback/logback.xml
ENV -Dorg.apache.felix.configadmin.plugin.interpolation.secretsdir=/mnt/configs

WORKDIR /app

USER appuser

CMD /app/start