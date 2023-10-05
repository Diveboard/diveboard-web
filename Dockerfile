# Use Ubuntu 20.04 LTS as the base image
FROM ubuntu:18.04

# Prevents prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Update the package list and install essential packages
RUN apt-get update && apt-get install -y \
    build-essential \
    sudo \
    vim \
    mysql-server \
    mysql-client \
    ntpdate \
    openssl \
    libxml2 \
    libxml2-dev \
    libxslt1-dev \
    libmagic-dev \
    libimage-exiftool-perl \
    imagemagick \
    nginx-extras \
    ffmpeg2theora \
    libpq5 \
    libmysqlclient-dev \
    libxslt-dev \
    libmagickwand-dev \
    spawn-fcgi \
    lsof \
    atop \
    libcache-cache-perl \
    man \
    redis-server \
    automake \
    autotools-dev \
    nginx-common \
    git \
    sphinxsearch \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    ca-certificates \
    gnupg \
    curl libcurl4 libcurl4-gnutls-dev \
    && apt-get clean


# Generating self-signed certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout /etc/ssl/private/myssl.key -out /etc/ssl/certs/myssl.crt  -subj "/C=US/ST=CA/L=San Francisco/O=Diveboard/OU=IT Department/CN=*.diveboard.com"

# Launch Mysql and allow access from docker
RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf

#RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN curl -sSL https://get.rvm.io | bash -s
RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && rvm install 1.9.3"

# Weirdly, it did not install above, so doing it again
RUN apt-get update && apt-get install -y \
    libmysqlclient-dev \
    libmagickwand-dev \
    libmagickcore-dev

# Install Bundler
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN /bin/bash -l -c "gem install bundler -v 1.3.6"

# Customize Bundler to use the correct paths
ENV LANG=en_US.UTF-8
ENV CURL_LIB_PATH /usr/lib/x86_64-linux-gnu
ENV CURL_INCLUDE_PATH /usr/include/x86_64-linux-gnu/curl
RUN /bin/bash -l -c "bundle config build.curb --with-curl-lib=$CURL_LIB_PATH --with-curl-include=$CURL_INCLUDE_PATH"
ENV MYSQL_LIB_PATH /usr/lib/x86_64-linux-gnu
ENV MYSQL_INCLUDE_PATH /usr/include/mysql
RUN /bin/bash -l -c "bundle config build.mysql2 --with-mysql-lib=$MYSQL_LIB_PATH --with-mysql-include=$MYSQL_INCLUDE_PATH"
ENV MAGICK_CONFIG_PATH /usr/bin/Magick-config
RUN /bin/bash -l -c "bundle config build.rmagick --with-opt-dir=/usr/include/ImageMagick-6"



RUN /bin/bash -l -c "bundle install --verbose"

# PAUSE
CMD ["sleep", "infinity"]

# RUN /bin/bash -l -c "bundle install --verbose"

# Launch Nginx
# RUN mkdir -p /home/diveboard/diveboard-web/current/public
# ADD config/docker/nginx.conf /etc/nginx/sites-enabled/default

# WORKDIR /home/diveboard/diveboard-web/current

# Expose NGinx & MySQL
# EXPOSE 80 443 3306
# ENV RAILS_ENV=production

# CMD /home/diveboard/diveboard-web/current/config/docker/start_all