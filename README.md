# Template files for use with Portainer

```
docker run -d -p 9000:9000 --restart always --name portainer  -v $PWD/data:/data -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer --logo https://foundries.io/static/img/logo.png --templates https://raw.githubusercontent.com/OpenSourceFoundries/ez/master/templates.json
```
