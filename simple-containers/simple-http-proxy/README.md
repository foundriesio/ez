# Simple HTTP Proxy

## Build the container

```
docker build -t simple-http-proxy --force-rm -f Dockerfile .
```

## Run the container

```
docker run --restart=always -d -t --net=host --read-only --name simple-http-proxy simple-http-proxy
```
