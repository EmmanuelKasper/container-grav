FROM debian:bullseye
LABEL maintainer="Emmanuel Kasper https://00formicapunk00.wordpress.com"

# Install dependencies
RUN apt-get update && apt-get install -y curl unzip apache2 php cron \
php-curl php-gd php-json php-mbstring php-xml php-zip php-opcache \
&& rm -rf /var/lib/apt/lists/*

# Enable Apache Rewrite + Expires Module, hide PHP and  Apache Version
RUN a2enmod rewrite expires php7.4 && \
    sed -i 's/ServerTokens OS/ServerTokens ProductOnly/g' \
    /etc/apache2/conf-available/security.conf

RUN rm -r /var/www/html/ && chown -R www-data:www-data /var/www
USER www-data

# Define Grav specific version of Grav or use latest stable
ARG GRAV_VERSION=latest

# Install grav
WORKDIR /var/www
RUN echo $GRAV_VERSION && \
    curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
    unzip grav-admin.zip && mv -T grav-admin html && rm grav-admin.zip

# Create cron job for Grav maintenance scripts
RUN (crontab -l; echo "* * * * * cd /var/www/html;/usr/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -

# Return to root user
USER root
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

CMD ["sh", "-c", "cron && apachectl -D FOREGROUND"]
