== Diveboard app

Some seed files use git-lfs since they are over Git's 100Mb limit
get git-lfs here: https://git-lfs.github.com/
check .gitattributes for the files you'll need to checkout manually


In order to setup a working environment, we are providing a Dockerfile to build a test container for the Diveboard application.

To setup the Docker container run from the docker CLI:

Create storage for the DB:
```
docker volume create --name hello
```

```
docker build -t diveboard .
```

Initialize the container:
```
docker run -v ${PWD}:/home/diveboard/diveboard-web/current diveboard /home/diveboard/diveboard-web/current/config/docker/init_env
```


You can then START the VM & connect to the container in interactive mode with:
```
docker run -v ${PWD}:/home/diveboard/diveboard-web/current  -v ${PWD}/tmp/mysql:/var/lib/mysql -p 80:80/tcp -p 443:443/tcp -p3306:3306/tcp diveboard
```

This will mount the current directory and allow you to use it as your dev codebase

A few last steps:
You need to then point your /etc/hosts to resolve the docker ip with "dev.diveboard.com"
You must forward ports 80>80 and 443>443 otherwise some resources won't load
