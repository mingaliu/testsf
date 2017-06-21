#1. Base OS image
FROM openjdk:8-jre-alpine

#2. Apache Zookeeper 
ARG ZOOKEEPER_VERSION=3.4.9
ARG ZOOKEEPER_MIRROR=http://www-eu.apache.org

LABEL name="zookeeper" version=${ZOOKEEPER_VERSION}

RUN apk add --no-cache wget bash

RUN mkdir /opt \
  && wget -q -O - ${ZOOKEEPER_MIRROR}/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz | tar -xzf - -C /opt \
  && mv /opt/zookeeper-* /opt/zookeeper \
  && chown -R root:root /opt/zookeeper

RUN addgroup -S zookeeper \
  && adduser -h /var/lib/zookeeper -G zookeeper -S -H -s /sbin/nologin zookeeper \
  && mkdir /var/lib/zookeeper \
  && chown -R zookeeper:zookeeper /var/lib/zookeeper

EXPOSE 2181 2888 3888

VOLUME ["/opt/zookeeper/conf", "/var/lib/zookeeper"]

#3. HDI integration layer
ADD ./src /
RUN chmod +x /start.sh

# install python and Azure cli
RUN apk add --update python py-pip python-dev make g++

ENV NODEJS_VERSION=5.6.0 \
    NODEJS_SHA256=3af2cc5e5970afc83e59f2065fea2e2df846a544a100cd3c0527f0db05bec27f \
    NPM_VERSION=3.7.1

RUN apk add --update nodejs

RUN npm install --global azure-cli@0.10.12 && \
	azure

ENTRYPOINT ["/start.sh"]

#4. All test dependency layer



