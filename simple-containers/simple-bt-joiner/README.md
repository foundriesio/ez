# Simple bt-joiner container

## Build the container

```
docker build -t simple-bt-joiner --force-rm -f Dockerfile .
```

## Run the container

```
docker run --restart=always -d -t --net=host --read-only --name simple-bt-joiner simple-bt-joiner
```
