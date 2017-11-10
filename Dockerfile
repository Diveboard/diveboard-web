# Dockerfile
FROM debian:wheezy
MAINTAINER Alexander Casassovici <alex@diveboard.com>



#update sources
ADD config/docker/sources.list /etc/apt/sources.list

# Add here your preinstall lib(e.g. imagemagick, mysql lib, pg lib, ssh config)

RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 9334A25F8507EFA5
RUN apt-get update -qq
RUN DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade


# intstall dependencies
RUN apt-get install -y sudo vim cron-apt  ruby1.9.1 ruby1.9.1-dev ri1.9.1 ruby1.9.1-full mysql-server mysql-client ntpdate ncftp build-essential  libssl-dev libcurl4-openssl-dev curl  libxml2 libxml2-dev libxslt1-dev libmysqlclient-dev libmagic-dev git libimage-exiftool-perl imagemagick nginx-extras libmagic1 ffmpeg exim4 libpq5 libmysqlclient-dev libmysqlclient16 sqlite sqlite3 libmysqlclient-dev libxslt-dev libxml2-dev changetrack filetraq logcheck syslog-summary  systraq duplicity imagemagick ntpdate iotop munin libmagickwand-dev imagemagick spawn-fcgi lsof atop libcache-cache-perl libwww-perl man clamav-daemon nodejs percona-xtrabackup redis-server nfs-common libsqlite3-dev percona-nagios-plugins automake autotools-dev nginx-common mysql-server

RUN curl -O http://sphinxsearch.com/files/sphinxsearch_2.1.8-release-1~wheezy_amd64.deb
RUN dpkg -i sphinxsearch_2.1.8-release-1~wheezy_amd64.deb

RUN /etc/init.d/sphinxsearch stop 
RUN update-rc.d -f sphinxsearch remove 

##Generating self-signed certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout /etc/ssl/private/myssl.key -out /etc/ssl/certs/myssl.crt  -subj "/C=US/ST=CA/L=San Francisco/O=Diveboard/OU=IT Department/CN=*.diveboard.com"

# Launch Mysql and allow access from docker
RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf


WORKDIR /tmp 
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN gem install bundler -v 1.3.5
RUN bundle install 

# Launch Nginx
RUN mkdir -p /home/diveboard/diveboard-web/current/public
ADD config/docker/nginx.conf /etc/nginx/sites-enabled/default

WORKDIR /home/diveboard/diveboard-web/current
#COPY Gemfile Gemfile
#RUN gem install bundler -v 1.3.5
#RUN bundle install

#Expose NGinx & MySQL
EXPOSE 80 443 3306
ENV RAILS_ENV=docker_development

CMD /home/diveboard/diveboard-web/current/config/docker/start_all


