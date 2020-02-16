# ------ HEADER ------ #
FROM nextcloud:17.0.3-apache
ARG DEBIAN_FRONTEND=noninteractive

# ------ RUN  ------ #
RUN mkdir -p /usr/share/man/man1 \
    && apt-get update && apt-get install -y \
        supervisor \
        ffmpeg \
        libmagickwand-dev \
        libgmp3-dev \
        libc-client-dev \
        libkrb5-dev \
        smbclient \
        libsmbclient-dev \
        libreoffice \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && ln -s "/usr/include/$(dpkg-architecture --query DEB_BUILD_MULTIARCH)/gmp.h" /usr/include/gmp.h \
    && docker-php-ext-install bz2 gmp imap \
    && pecl install imagick smbclient \
    && docker-php-ext-enable imagick smbclient \
    && mkdir /var/log/supervisord /var/run/supervisord

ENV NEXTCLOUD_UPDATE=1

ADD ./source/supervisord.conf /etc/supervisor/supervisord.conf
ADD ./source/smb.conf /etc/samba/smb.conf

RUN sed -i 's/:80/:8080/g' /etc/apache2/sites-available/000-default.conf \
        && sed -i 's/:443/:8443/g' /etc/apache2/sites-available/default-ssl.conf
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf \
        && sed -i 's/Listen 443/Listen 8443/g' /etc/apache2/ports.conf

RUN usermod -u 1000 www-data \
        && groupmod -g 1000 www-data \
        && chown -R www-data:www-data /var/www /var/log/supervisord /var/run/supervisord

# ------ CMD/START/STOP ------ #
USER www-data
CMD ["/usr/bin/supervisord"]
