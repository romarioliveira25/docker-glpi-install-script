# Docker GLPI - Automated installation

## TODO - Documentation and to organize all it README file :-P

PHP 7.2 dependencies

Mandatory extensions

curl: for CAS authentication, GLPI version check, Telemetry, …;
fileinfo: to get extra informations on files;
gd: to generate images;
json: to get support for JSON data format;
mbstring: to manage multi bytes characters;
mysqli: to connect and query the database;
session: to get user sessions support;
zlib: to get backup and restore database functions;
simplexml;
xml.

(php7-curl-7.2.10-r0 php7-fileinfo-7.2.10-r0 php7-gd-7.2.10-r0 php7-json-7.2.10-r0 php7-mbstring-7.2.10-r0 php7-mysqli-7.2.10-r0 php7-session-7.2.10-r0 php7-common-7.2.10-r0 php7-simplexml-7.2.10-r0 php7-xml-7.2.10-r0)

Optional extensions

cli: to use PHP from command line (scripts, automatic actions, and so on);
domxml: used for CAS authentication;
imap: used for mail collector ou user authentication;
ldap: use LDAP directory for authentication;
openssl: secured communications;
xmlrpc: used for XMLRPC API.
APCu: may be used for cache; among others (see caching configuration (in french only).

(php7-dom-7.2.10-r0 php7-imap-7.2.10-r0 php7-ldap-7.2.10-r0 php7-openssl-7.2.10-r0 php7-xmlrpc-7.2.10-r0 php7-apcu-5.1.11-r2)

Composer required extensions
(php7-ctype php7-xmlreader php7-tokenizer php7-xmlwriter)

GLPI plugins

    - Dashboard
    - Formcreator
    - Fusion Inventory
    - Data Injection
    - GLPI Modifications
    - Web notifications

## References/Inspiration to develop it! Big thanks for all!

### Multi-version install
https://github.com/DiouxX/docker-glpi

### Plugins installation and Cron jobs enable
https://github.com/Turgon37/docker-glpi

### GLPI CLI install
https://glpi-install.readthedocs.io/en/latest/command-line.html

### General install configuration
https://glpi-install.readthedocs.io/en/latest/


