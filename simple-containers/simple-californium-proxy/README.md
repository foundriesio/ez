# Simple Californium proxy

## Build the container

```
docker build -t simple-californium-proxy --force-rm -f Dockerfile .
```

## Run the container

```
docker run --restart=always -d -t --net=host --read-only --name simple-californium-proxy simple-californium-proxy
```
