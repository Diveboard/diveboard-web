# Dockerfile
FROM debian:jessie
MAINTAINER Alexander Casassovici <alex@diveboard.com>


RUN apt-get update
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -q && \
    apt-get install -qy procps curl ca-certificates gnupg2 build-essential sudo vim mysql-server mysql-client ntpdate libssl-dev libcurl4-openssl-dev libxml2 libxml2-dev libxslt1-dev libmagic-dev libimage-exiftool-perl imagemagick nginx-extras libmagic1 ffmpeg2theora libpq5 libmysqlclient-dev libmysqlclient18 sqlite sqlite3 libxslt-dev libxml2-dev imagemagick ntpdate  libmagickwand-dev imagemagick spawn-fcgi lsof atop libcache-cache-perl man redis-server libsqlite3-dev automake autotools-dev nginx-common mysql-server git --no-install-recommends && apt-get clean

##Generating self-signed certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout /etc/ssl/private/myssl.key -out /etc/ssl/certs/myssl.crt  -subj "/C=US/ST=CA/L=San Francisco/O=Diveboard/OU=IT Department/CN=*.diveboard.com"

# Launch Mysql and allow access from docker
RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf

RUN gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN curl -sSL https://get.rvm.io | bash -s
RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && rvm install 1.9.3"

WORKDIR /tmp 
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN /bin/bash -l -c "gem install bundler -v 1.3.6"
RUN /bin/bash -l -c "bundle install"


# Launch Nginx
RUN mkdir -p /home/diveboard/diveboard-web/current/public
ADD config/docker/nginx.conf /etc/nginx/sites-enabled/default

WORKDIR /home/diveboard/diveboard-web/current

#Expose NGinx & MySQL
EXPOSE 80 443 3306
ENV RAILS_ENV=docker_development

CMD /home/diveboard/diveboard-web/current/config/docker/start_all


