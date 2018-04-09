# a simple mosquitto broker

## Build the container

```
docker build -t simple-mosquitto-broker --force-rm -f Dockerfile .
```

## Run the container

```
docker run --restart=always -d -t --net=host --read-only --name simple-mosquitto-broker simple-mosquitto-broker
```
