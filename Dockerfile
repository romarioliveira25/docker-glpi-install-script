FROM alpine:3.8

LABEL maintainer  = "Romário Oliveira <romario1025@gmail.com"
LABEL version     = "1.0.0"
LABEL description = "Docker image to install the servicedesk system GLPI"

ENV WORKDIR_PATH /var/www/html

RUN apk update && apk --no-cache add php7 \
    ######################################
    ## PHP 7.2 | Mandatory extensions ##
    ######################################
        php7-curl \
        php7-fileinfo \
        php7-gd \
        php7-json \
        php7-mbstring \
        php7-mysqli \
        php7-session \
        php7-common \
        php7-simplexml \
        php7-xml \
        php7-apache2 \
    ######################################
    ##  PHP 7.2 | Optional extensions   ##
    ######################################
        php7-dom \
        php7-imap \
        php7-ldap \
        php7-openssl \
        php7-xmlrpc \
        php7-apcu \
        php7-opcache \
        php7-pear \
    ##################################################
    ##  GLPI 9.3 | composer requested dependencies  ##
    ##################################################
        php7-ctype \
        php7-xmlreader \
        php7-tokenizer \
        php7-xmlwriter \
    ######################################
    #####       Apache2 webserver     ####
    ######################################
        apache2 \
    ######################################
    #####       Apache2 NTLM AUTH     ####
    ######################################
        apache-mod-auth-ntlm-winbind \
        samba \
        samba-winbind \
        samba-winbind-clients \
    ######################################
    ########        Utils        #########
    ######################################
        util-linux \
        curl \
        jq

WORKDIR ${WORKDIR_PATH}

ADD scripts/glpi_setup.sh .
ADD config/php/ /etc/php7/conf.d
ADD config/apache/ /etc/apache2/conf.d
ADD config/samba/ /etc/samba
ADD config/dns/ /etc/

RUN chmod +x glpi_setup.sh

ENTRYPOINT [ "./glpi_setup.sh" ]