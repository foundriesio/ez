FROM alpine:latest

MAINTAINER Michael Scott "michael@opensourcefoundries.com"
# Californium proxy code located at:
# https://github.com/OpenSourceFoundries/californium/commits/osf-2.0.x

RUN apk add --no-cache wget openjdk8-jre-base ca-certificates

RUN mkdir -p /opt/cf-proxy
COPY Californium.properties /opt/cf-proxy
COPY ProxyMapping.properties /opt/cf-proxy
COPY Proxy.properties /opt/cf-proxy
COPY cf-proxy-2.0.0-SNAPSHOT.jar /opt/cf-proxy

EXPOSE 5682

CMD cd /opt/cf-proxy && java -jar cf-proxy-2.0.0-SNAPSHOT.jar
