#!/bin/sh

#=======================================================================================================================================
#title           :glpi_setup.sh
#description     :This script will make all environment configuration necessary to use the service desk solution GLPI in automated way.
#author		       :Romário Oliveira <romario1025@gmail.com>
#date            :20180925
#version         :1.0.0    
#usage		       :sh glpi_setup.sh
#notes           :
#bash_version    :BusyBox v1.28.4
#=======================================================================================================================================

set -e

FOLDER_GLPI=${WORKDIR_PATH}/glpi
FOLDER_GLPI_PLUGINS=${FOLDER_GLPI}/plugins
FOLDER_GLPI_SCRIPTS=${FOLDER_GLPI}/scripts
FOLDER_GLPI_BIN=${FOLDER_GLPI}/bin

#####################
## Install plugins ##
#####################

# Install a plugin
# param1: the name of the plugin (directory)
# param2: the url to download the plugin from
function install_plugin_helper() {
  PLUGIN="${1}"
  URL="${2}"
  FILE="$(basename "$URL")"

  # continue if plugin already installed
  if [ -d "$PLUGIN" ]; then
    echo "..plugin ${PLUGIN} already installed"
    continue
  fi

  # Download plugin source if not exists
  if [ ! -f "${FILE}" ]; then
    echo -e "\n..downloading plugin '${PLUGIN}' from '${URL}'"
    curl -o "${FILE}" -L "${URL}"
  fi

  # extract the archive according to the extension
  echo -e "\n..extracting plugin '${FILE}'"
  case "$FILE" in
    *.tar.gz)
      tar xzf ${FILE} -C ${FOLDER_GLPI_PLUGINS}
      ;;
    *.tar.bz2)
      tar xjf ${FILE} -C ${FOLDER_GLPI_PLUGINS}
      ;;
    *.zip)
      unzip -o ${FILE} -d ${FOLDER_GLPI_PLUGINS} -q
      ;;
    *)
      echo "..#ERROR# unknown extension for ${FILE}." 1>&2
      false
      ;;
  esac
  if [ $? -ne 0 ]; then
    echo -e "\n..#ERROR# failed to extract plugin ${PLUGIN}" 1>&2
    continue
  fi

  # remove source and set file permissions
  echo -e "\n..removing file '${FILE}'"
  rm -f ${FILE}

  echo -e "\n..changing folder permissions"
  chown -R apache:apache ${FOLDER_GLPI_PLUGINS}/${PLUGIN}
  chmod -R g=rX,o=--- ${FOLDER_GLPI_PLUGINS}/${PLUGIN}
}

########################################
## Download and installation proccess ##
########################################
function part1() {
  echo -e "GLPI SETUP STARTED\n\n"

  echo -e "STEP 1 - Obtaining GLPI version info ...\n\n"

  [[ ! "$GLPI_VERSION" ]] \
    && GLPI_VERSION=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

  SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${GLPI_VERSION} | jq .assets[0].browser_download_url | tr -d \")
  TAR_GLPI=$(basename ${SRC_GLPI})

	echo -e "STEP 2 - Downloading GLPI version ${GLPI_VERSION} ...\n\n"
	curl -O -L ${SRC_GLPI}
	
	echo -e "\n\nSTEP 3 - Extracting files ...\n\n"
	tar -xzf ${WORKDIR_PATH}/${TAR_GLPI} -C ${WORKDIR_PATH}

	echo -e "STEP 4 - Removing compressed file ...\n"
	rm -Rf ${WORKDIR_PATH}/${TAR_GLPI}

  if [ $GLPI_CLI_INSTALL ]; then
  
    echo -e "\nSTEP 5 - Runnging GLPI CLI install ...\n\n"

    echo -e "Hey, keep in mind which this process can be a bit delayed...\n"
    echo -e "No problem, just keep looking the progress and relax :-D\n"

    if echo "$GLPI_VERSION" | grep -q '9.4.*'; then
      if [ -f "${FOLDER_GLPI_BIN}/console" ]; then
        /usr/bin/php ${FOLDER_GLPI_BIN}/console --no-interaction -vvv glpi:database:install --db-host=$GLPI_DB_HOST --db-name=$GLPI_DB_NAME --db-user=$GLPI_DB_USER --db-password=$GLPI_DB_PASS --default-language=$GLPI_LANG
      else
        echo -e "GLPI version ${GLPI_VERSION} has no support for console application\n"
      fi
    else
      if [ -f "${FOLDER_GLPI_SCRIPTS}/cliinstall.php" ]; then
        /usr/bin/php ${FOLDER_GLPI_SCRIPTS}/cliinstall.php --host=$GLPI_DB_HOST --db=$GLPI_DB_NAME --user=$GLPI_DB_USER --pass=$GLPI_DB_PASS --lang=$GLPI_LANG --force
      else
        echo -e "GLPI version ${GLPI_VERSION} has no support for CLI install\n"
      fi
    fi
  else
    echo -e "GLPI CLI install option has not been selected in .env file\n"
  fi
}

##################################
## GLPI directory configuration ##
##################################
function part2() {
  echo -e "\n\nSTEP 6 - Configuring glpi files and directories ...\n\n"
  
  if [[ ! -e /var/lib/glpi ]]; then
    mkdir -p /var/lib/glpi
  fi

  mkdir -p /etc/glpi && \
  mv -v ${FOLDER_GLPI}/files/* /var/lib/glpi && \
  mv -v ${FOLDER_GLPI}/config/* /etc/glpi

  echo -e "<?php\ndefine('GLPI_CONFIG_DIR', '/etc/glpi');\n\nif (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {\n\trequire_once GLPI_CONFIG_DIR . '/local_define.php';\n}" > glpi/inc/downstream.php

  echo -e "<?php\ndefine('GLPI_VAR_DIR', '/var/lib/glpi');\ndefine('GLPI_LOG_DIR', '/var/lib/glpi/_log');" > /etc/glpi/local_define.php

  echo -e "\nSTEP 7 - Setting group apache to glpi directories and files ...\n\n"
  chown -R apache:apache glpi /etc/glpi /var/lib/glpi

  # Renaming install.php for security porpourses
  mv ${FOLDER_GLPI}/install/install.php ${FOLDER_GLPI}/install/install.php.disabled
}

###################################
## GLPI cron jobs configuration ###
###################################
function part3() {
  echo -e "STEP 8 - Setting cron tasks ...\n\n"

  if [ $GLPI_ENABLE_CRONJOB ]; then
    echo -e "
    # Add scheduled task by cron and enable
    */2 * * * * apache /usr/bin/php ${FOLDER_GLPI}/front/cron.php &>/dev/null

    # Sync GLPI users from AD/LDAP – Every day 22pm
    00 22 * * * apache /usr/bin/php -q -f ${FOLDER_GLPI_SCRIPTS}/ldap_mass_sync.php action=2
     
    # Unlock automatic actions blocked in GLPI – Each 15min
    */15 * * * * apache /usr/bin/php ${FOLDER_GLPI_SCRIPTS}/unlock_tasks.php
     
    # Aplication and Database backup - TODO
    #0 23 * * * sh /backup/backup_glpi.sh
    
    " >> /etc/crontabs/glpi
  else
    echo -e "GLPI cron jobs option is not enabled in .env file\n"
  fi
}

###############################
## GLPI plugins installation ##
###############################
function part4() {
  echo -e "STEP 9 - Installing GLPI plugins\n\n"

  if [ ! -z "${GLPI_INSTALL_PLUGINS}" ]; then
    OLDIFS=$IFS
    IFS=','

    for ITEM in ${GLPI_INSTALL_PLUGINS}; do
      IFS=$OLDIFS
      NAME="${ITEM%|*}"
      URL="${ITEM#*|}"

      install_plugin_helper "${NAME}" "${URL}"
    done
  else
    echo -e "\nHas not GLPI plugins to be installed.\n"
  fi
}

###############################
## GLPI post install scripts ##
###############################
function part5() {
  echo -e "\nSTEP 10 - Running post install scripts"
  echo -e "\nInnoDB migration..."

  if echo "$GLPI_VERSION" | grep -q '9.4.*'; then
    if [ -f "${FOLDER_GLPI_BIN}/console" ]; then
      /usr/bin/php ${FOLDER_GLPI_BIN}/console --no-interaction -vvv glpi:migration:myisam_to_innodb
    else
      echo -e "GLPI version ${GLPI_VERSION} has no support for console application\n"
    fi
  else
    if [ -f "${FOLDER_GLPI_SCRIPTS}/innodb_migration.php" ]; then
      /usr/bin/php ${FOLDER_GLPI_SCRIPTS}/innodb_migration.php
    else
      echo -e "GLPI version ${GLPI_VERSION} has no support for innodb migration scripts\n"
    fi
  fi
}

#######################
## Starting services ##
#######################
function part6() {
  echo -e "\n\nSTEP 11 - Starting cron service ...\n\n"

  # Start cron service
  /usr/sbin/crond

  echo -e "\n\nSTEP 12 - Starting apache service ...\n\n"

  # Creating folders not created by related services
  if [ -d "/run/apache2" ]; then
    echo "Apache2 pid folder already created"
  else
    mkdir /run/apache2
  fi

  # forward request and error logs to docker log collector
  ln -sf /dev/stdout /var/log/apache2/access.log
	ln -sf /dev/stderr /var/log/apache2/error.log

  echo -e "GLPI SETUP FINISHED\n\n"

  # Start apache2 service
  exec /usr/sbin/httpd -DFOREGROUND
}

if [ -d "${FOLDER_GLPI}" ] && [ "$(ls -A ${FOLDER_GLPI})" ]; then
	echo "GLPI is already installed"
else
  part1
  part2
  part3
  part4
  part5
fi

part6