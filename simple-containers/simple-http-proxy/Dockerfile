FROM nginx:mainline-alpine

MAINTAINER Ricardo Salveti "ricardo@opensourcefoundries.com"

COPY nginx-http-proxy.conf /etc/nginx/nginx.conf

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
