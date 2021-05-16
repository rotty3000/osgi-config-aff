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

FROM alpine:latest AS build

RUN mkdir -p /app/bin /app/log /app/configs

COPY target/exec.jar /app/exec.jar
COPY default-logback.xml /app/log/logback.xml

RUN \
	apk add unzip tree && \
	unzip /app/exec.jar -d /app/bin && \
	rm /app/exec.jar /app/bin/start /app/bin/start.bat && \
	rm -rf /app/bin/META-INF/maven /app/bin/OSGI-OPT

COPY start /app/bin/start

FROM azul/zulu-openjdk-alpine:11-jre-headless

COPY --from=build /app /app

RUN \
	apk add dumb-init tree busybox-extras && \
	adduser -s /bin/false -D appuser && \
	chmod +x /app/bin/start && \
	chown -R appuser:appuser /app

WORKDIR /app/bin

USER appuser

CMD ["dumb-init", "/app/bin/start"]
