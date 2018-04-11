FROM alpine

RUN apk add --no-cache python3-dev py3-pip docker git bash curl
RUN pip3 install --upgrade pip docker-compose
COPY compose-files/* /
COPY compose-launcher/start.sh /
RUN chmod +x /*.sh
CMD /start.sh
