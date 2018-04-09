FROM alpine

RUN apk add --no-cache python3-dev py3-pip docker git bash curl
RUN pip3 install --upgrade pip docker-compose
COPY compose-files/*.yml /
COPY compose-launcher/start.sh /
RUN chmod +x /start.sh
CMD /start.sh
