[![Slack Chat](http://slack.diveboard.com/badge.svg "Join us. Anyone is welcome!")](http://slack.diveboard.com/) ⇦ Join us!


![Diveboard logo](https://cdn.diveboard.com/img/drawer/svg/logo_topbar_mobile.svg "Diveboard")

DIVEBOARD PLATFORM APP
========

Introduction
--------
This repository holds the code of the Diveobard web application.
As described in the main [documentation](https://github.com/Diveboard/Documentation), this piece is responsible for storing, making sense, displaying and exposing the user's logs.

It provides:
* A public API ([documentation](https://github.com/Diveboard/Documentation/API.md)) 
* A web frontend - the master branch is the current live one on [www.diveboard.com](http://www.diveboard.com)
  * Translations of the frontend are done through [OneSkyApp](https://diveboard.oneskyapp.com) 
* a set of jobs a.k.a. workers 

It relies on:
* a Mysql database operated by Diveboard. A kickstart seed is available in this repo expurged from user data.
* GCP Storage buckets to keep images & videos
* a Rails stack (see the Dockerfile for full stack details)


Setting up a Development Environment
--------

Some seed files use git-lfs since they are over Git's 100Mb limit
get git-lfs here: https://git-lfs.github.com/
check .gitattributes for the files you'll need to checkout manually

In order to get the database seed required for the dev environment environment to run you will need to run
```
git lfs pull
``` 

In order to setup a working environment, we are providing a Dockerfile to build a test container for the Diveboard application.

To setup the Docker container run from the docker CLI:

```
docker build -t diveboard .
#OR if you want a clean start
docker build --no-cache -t diveboard .
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

Need help?
------
Join us on Slack: ![Join our Slack](http://slack.diveboard.com/badge.svg "Diveboard Slack") 
