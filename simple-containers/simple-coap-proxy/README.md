# Simple CoAP Proxy

## Build the container

```
docker build -t simple-coap-proxy --force-rm -f Dockerfile .
```

## Run the container

```
docker run --restart=always -d -t --net=host --read-only --name simple-coap-proxy simple-coap-proxy
```
