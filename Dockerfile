FROM alpine:3.18
ENV TZ=America/Denver

ARG PHP_VERSION="82"
ARG S6_OVERLAY_VERSION="3.1.5.0"
ARG COMPOSER_VERSION="2"
ARG XDEBUG_VERSION="3.1.3"


# Common PHP Frameworks Env Variables
ENV APP_ENV prod
ENV APP_DEBUG 0


# Set SHELL flags for RUN commands to allow -e and pipefail
# Rationale: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# ----------------
# PHP Dependencies
# ----------------
RUN apk update && apk upgrade

RUN apk --update add \
  curl \
  tzdata \
  nginx \
#   nginx=${NGINX_VERSION} \
  s6-overlay \
  php${PHP_VERSION}-cli \
  php${PHP_VERSION}-fpm \
  php${PHP_VERSION}-gd \
  php${PHP_VERSION}-json \
  php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-pdo \
  php${PHP_VERSION}-pgsql \
  php${PHP_VERSION}-pdo_pgsql \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-redis \
  php${PHP_VERSION}-openssl \
  php${PHP_VERSION}-tokenizer \
  php${PHP_VERSION}-opcache \
  && rm -rf /var/cache/apk/* 


#makes updating php versions easier
RUN ln -s /usr/bin/php${PHP_VERSION} /usr/bin/php
RUN ln -s /etc/php${PHP_VERSION}/ /etc/php
RUN ln -s /usr/sbin/php-fpm${PHP_VERSION} /usr/bin/php-fpm

# Configure php-fpm
RUN mkdir -p /run/php/
RUN touch /run/php/php-fpm.pid
RUN touch /run/php/php-fpm.sock

#COPY .docker/php/www.conf /etc/php/php-fpm.d/www.conf
COPY .docker/php/php-fpm.conf /etc/php/php-fpm.conf
#test php-fpm configs
RUN php-fpm -t


# set up nginx config
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY .docker/nginx/default.conf /etc/nginx/conf.d/default.conf
# test nginx config
RUN nginx -t


# configure s6-overlay (supervisor)
# a directory is created for each service a simple file named type with contents of "longrun" tells s6 this is to run constantly not just once
# a run script is created to execute the service and a finish script is created to handle exit codes properly when docker/k8s kills a container
# the dependancies.d folder has empty files with names of services to start first base for php-fpm and php-fpm for nginx
# an empty file with the service name is created in the user/contents.d folder to actually start the nginx and php-fpm services on contianer startup/boot
RUN mkdir /etc/s6-overlay/s6-rc.d/php-fpm && echo "longrun" > /etc/s6-overlay/s6-rc.d/php-fpm/type 
COPY --chmod=777 .docker/php/up /etc/s6-overlay/s6-rc.d/php-fpm/run
COPY --chmod=777 .docker/php/finish /etc/s6-overlay/s6-rc.d/php-fpm/finish
RUN mkdir /etc/s6-overlay/s6-rc.d/php-fpm/dependencies.d && touch /etc/s6-overlay/s6-rc.d/php-fpm/dependencies.d/base
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/php-fpm 

RUN mkdir /etc/s6-overlay/s6-rc.d/nginx && echo "longrun" > /etc/s6-overlay/s6-rc.d/nginx/type
COPY --chmod=777 .docker/nginx/up /etc/s6-overlay/s6-rc.d/nginx/run
COPY --chmod=777 .docker/php/finish /etc/s6-overlay/s6-rc.d/nginx/finish
RUN mkdir /etc/s6-overlay/s6-rc.d/nginx/dependencies.d && touch /etc/s6-overlay/s6-rc.d/nginx/dependencies.d/php-fpm
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/nginx



# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN mkdir /app
RUN touch /run/php/php-fpm.sock
RUN chown -R nobody:nobody /app /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

WORKDIR /app

# Add application
COPY --chown=nobody src/ /app

EXPOSE 80
CMD ["/init"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1/fpm-ping

## probably have from alpine as base from base as dev then as source then from source as testing and from source as prod
## maybe with different config ex: enable access logs and have source add code only for test and prod
## assume volume mounts for dev dif composer for dev and test/prod
