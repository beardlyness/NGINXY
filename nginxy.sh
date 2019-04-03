#!/usr/bin/env bash
#===============================================================================================================================================
# (C) Copyright 2019 NGINXY a project under the Crypto World Foundation (https://cryptoworld.is).
#
# Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#===============================================================================================================================================
# title            :NGINXY
# description      :This script will make it super easy to setup a Reverse Proxy with NGINX.
# author           :The Crypto World Foundation.
# contributors     :beard
# date             :04-02-2019
# version          :0.0.10 Alpha
# os               :Debian/Ubuntu
# usage            :bash nginxy.sh
# notes            :If you have any problems feel free to email the maintainer: beard [AT] cryptoworld [DOT] is
#===============================================================================================================================================

# Force check for root
  if ! [ $(id -u) = 0 ]; then
    echo "You need to be logged in as root!"
    exit 1
  fi

  # Setting up an update/upgrade global function
    function upkeep() {
      echo "Performing upkeep.."
        apt-get update -y
        apt-get dist-upgrade -y
        apt-get clean -y
    }

  # Setting up different NGINX branches to prep for install
    function stable() {
        echo deb http://nginx.org/packages/$system/ $flavor nginx > /etc/apt/sources.list.d/$flavor.nginx.stable.list
        echo deb-src http://nginx.org/packages/$system/ $flavor nginx >> /etc/apt/sources.list.d/$flavor.nginx.stable.list
          wget https://nginx.org/keys/nginx_signing.key
          apt-key add nginx_signing.key
      }

    function mainline() {
        echo deb http://nginx.org/packages/mainline/$system/ $flavor nginx > /etc/apt/sources.list.d/$flavor.nginx.mainline.list
        echo deb-src http://nginx.org/packages/mainline/$system/ $flavor nginx >> /etc/apt/sources.list.d/$flavor.nginx.mainline.list
          wget https://nginx.org/keys/nginx_signing.key
          apt-key add nginx_signing.key
      }

      # Attached func for NGINX branch prep.
        function nginx_default() {
          echo "Installing NGINX.."
            apt-get install nginx
            service nginx status
          echo "Raising limit of workers.."
            ulimit -n 65536
            ulimit -a
          echo "Setting up Security Limits.."
            wget -O /etc/security/limits.conf https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/security/limits.conf
          echo "Setting up background NGINX workers.."
            wget -O /etc/default/nginx https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/default/nginx
            echo "Setting up configuration file for NGINX main configuration.."
              wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/nginx/nginx.conf
          echo "Setting up folders.."
            mkdir -p /etc/engine/ssl/live
            mkdir -p /var/www/html/proxy/live
        }


        function proxy_default()  {
          read -r -p "Domain Name: (Leave { HTTPS:/// | HTTP:// | WWW. } out of the domain) " DOMAIN
            if [[ "${DOMAIN,,}" ]]
              then
                echo "Setting up configuration file for NGINX Proxy.."
                  wget -O /etc/nginx/conf.d/nginx-proxy.conf https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/nginx/conf.d/nginx-proxy.conf
                echo "Changing 'server_name foobar' >> server_name '$DOMAIN' .."
                  sed -i 's/server_name foobar/server_name '$DOMAIN'/g' /etc/nginx/conf.d/nginx-proxy.conf
                echo "Domain Name has been set to: '$DOMAIN' "
                echo "Removing Default NGINX Configuration files.."
                  mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.old
            fi

            read -r -p "Please enter the IP Address for the Backend IP: " IPA
              if [[ "${IPA},,}" =~ (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) ]]
                then
                  echo "Changing 'server Main-A' >> server '$IPA' .."
                    sed -i 's/$backend/'$IPA'/g' /etc/nginx/conf.d/nginx-proxy.conf
                  echo "Backend IP Address has been set to: '$IPA' "
              fi
        }

        function proxy_upstream() {
          read -r -p "Domain Name: (Leave { HTTPS:/// | HTTP:// | WWW. } out of the domain) " DOMAIN
            if [[ "${DOMAIN,,}" ]]
              then
                echo "Setting up configuration file for NGINX Proxy.."
                  wget -O /etc/nginx/conf.d/nginx-proxy.conf https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/nginx/conf.d/nginx-upstream.conf
                echo "Changing 'server_name foobar' >> server_name '$DOMAIN' .."
                  sed -i 's/server_name foobar/server_name '$DOMAIN'/g' /etc/nginx/conf.d/nginx-proxy.conf
                echo "Domain Name has been set to: '$DOMAIN' "
                echo "Removing Default NGINX Configuration files.."
                  mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.old
            fi

            read -r -p "Please enter the IP Address for Upstream IP: " IPA
              if [[ "${IPA},,}" =~ (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) ]]
                then
                  echo "Changing 'server Main-A' >> server '$IPA' .."
                    sed -i 's/server Main-A/server '$IPA'/g' /etc/nginx/conf.d/nginx-proxy.conf
                  echo "Upstream IP Address has been set to: '$IPA' "
              fi

              read -r -p "Please enter the IP Address for Upstream IP: " IPB
                if [[ "${IPB},,}" =~ (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) ]]
                  then
                    echo "Changing 'server Main-B' >> server '$IPB' .."
                      sed -i 's/server Main-B/server '$IPB'/g' /etc/nginx/conf.d/nginx-proxy.conf
                    echo "Upstream IP Address has been set to: '$IPB' "
                fi

                read -r -p "Please enter the IP Address for Upstream IP: " IPC
                  if [[ "${IPC},,}" =~ (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) ]]
                    then
                      echo "Changing 'server Main-C' >> server '$IPC' .."
                        sed -i 's/server Main-C/server '$IPC'/g' /etc/nginx/conf.d/nginx-proxy.conf
                      echo "Upstream IP Address has been set to: '$IPC' "
                  fi

                  read -r -p "Please enter the IP Address for Upstream IP: " IPD
                    if [[ "${IPD},,}" =~ (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) ]]
                      then
                        echo "Changing 'server Main-D' >> server '$IPD' .."
                          sed -i 's/server Main-D/server '$IPD'/g' /etc/nginx/conf.d/nginx-proxy.conf
                        echo "Upstream IP Address has been set to: '$IPD' "
                    fi
        }

        #Prep for Custom Error Page Handling
          function custom_errors() {
            echo "Setting up folders.."
              mkdir -p /var/www/html/proxy/live/errors
            echo "Grabbing Custom Error Pages & Handling from GitHub.."
              wget https://github.com/beardlyness/nginxy-custom-errors/archive/master.tar.gz -O - | tar -xz -C /var/www/html/proxy/live/errors/  && mv /var/www/html/proxy/live/errors/NGINXY-Custom-Errors-master/* /var/www/html/proxy/live/errors/
            echo "Removing temporary files/folders.."
              rm -rf /var/www/html/proxy/live/NGINXY-Custom-Errors-master && rm -rf /var/www/html/proxy/live/errors/LICENSE
          }

        #Prep for SSL setup & install via ACME.SH script | Check it out here: https://github.com/Neilpang/acme.sh
          function ssldev() {
                echo "Preparing for SSL install.."
                  wget -O -  https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh | INSTALLONLINE=1  sh
                  reset
                  service nginx stop
                  openssl dhparam -out /etc/engine/ssl/live/dhparam.pem 2048
                  bash ~/.acme.sh/acme.sh --issue --standalone -d $DOMAIN -ak 4096 -k 4096 --force
                  bash ~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
                    --key-file    /etc/engine/ssl/live/ssl.key \
                    --fullchain-file    /etc/engine/ssl/live/certificate.cert \
                    --reloadcmd   "service nginx restart"
          }

          #Prep for SSL setup for Qualys rating
          function sslqualy() {
            echo "Preparing to setup NGINX to meet Qualys 100% Standards.."
              sed -i 's/ssl_prefer_server_ciphers/#ssl_prefer_server_ciphers/g' /etc/nginx/conf.d/nginx-proxy.conf
              sed -i 's/#ssl_ciphers/ssl_ciphers/g' /etc/nginx/conf.d/nginx-proxy.conf
              sed -i 's/#ssl_ecdh_curve/ssl_ecdh_curve/g' /etc/nginx/conf.d/nginx-proxy.conf
            echo "Generating a 4096 DH Param. This may take a while.."
              openssl dhparam -out /etc/engine/ssl/live/dhparam.pem 4096
          }

      # Setting up different PHP Version branches to prep for install
        function phpdev() {
          echo "Setting up PHP Branches for install.."
            wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
          echo "deb https://packages.sury.org/php/ $flavor main" | tee /etc/apt/sources.list.d/php.list
        }


#START

# Checking for multiple "required" pieces of software.
    if
      echo -e "\033[92mPerforming upkeep of system packages.. \e[0m"
        upkeep
      echo -e "\033[92mChecking software list..\e[0m"

      [ ! -x  /usr/bin/lsb_release ] || [ ! -x  /usr/bin/socat ] || [ ! -x  /usr/bin/wget ] || [ ! -x  /usr/bin/apt-transport-https ] || [ ! -x  /usr/bin/dirmngr ] || [ ! -x  /usr/bin/ca-certificates ] || [ ! -x  /usr/bin/dialog ] ; then

        echo -e "\033[92mlsb_release: checking for software..\e[0m"
        echo -e "\033[34mInstalling lsb_release, Please Wait...\e[0m"
          apt-get install lsb-release

        echo -e "\033[92msocat: checking for software..\e[0m"
        echo -e "\033[34mInstalling socat, Please Wait...\e[0m"
          apt-get install socat

        echo -e "\033[92mwget: checking for software..\e[0m"
        echo -e "\033[34mInstalling wget, Please Wait...\e[0m"
          apt-get install wget

        echo -e "\033[92mapt-transport-https: checking for software..\e[0m"
        echo -e "\033[34mInstalling apt-transport-https, Please Wait...\e[0m"
          apt-get install apt-transport-https

        echo -e "\033[92mdirmngr: checking for software..\e[0m"
        echo -e "\033[34mInstalling dirmngr, Please Wait...\e[0m"
          apt-get install dirmngr

        echo -e "\033[92mca-certificates: checking for software..\e[0m"
        echo -e "\033[34mInstalling ca-certificates, Please Wait...\e[0m"
          apt-get install ca-certificates

        echo -e "\033[92mdialog: checking for software..\e[0m"
        echo -e "\033[34mInstalling dialog, Please Wait...\e[0m"
          apt-get install dialog
    fi

    # Grabbing info on active machine.
        flavor=`lsb_release -cs`
        system=`lsb_release -i | grep "Distributor ID:" | sed 's/Distributor ID://g' | sed 's/["]//g' | awk '{print tolower($1)}'`


# NGINX Arg main
read -r -p "Do you want to setup NGINX as a Reverse Proxy? (Y/N) " REPLY
  case "${REPLY,,}" in
    [yY]|[yY][eE][sS])
      HEIGHT=20
      WIDTH=120
      CHOICE_HEIGHT=2
      BACKTITLE="NGINXY"
      TITLE="NGINX Branch Builds"
      MENU="Choose one of the following Build options:"

      OPTIONS=(1 "Stable"
               2 "Mainline")

      CHOICE=$(dialog --clear \
                      --backtitle "$BACKTITLE" \
                      --title "$TITLE" \
                      --menu "$MENU" \
                      $HEIGHT $WIDTH $CHOICE_HEIGHT \
                      "${OPTIONS[@]}" \
                      2>&1 >/dev/tty)


# Attached Arg for dialogs $CHOICE output
    case $CHOICE in
      1)
        echo "Grabbing Stable build dependencies.."
          stable
          upkeep
          nginx_default

          # NGINX Proxy Sub Arg
          read -r -p "Do you want to setup NGINX as a single base Reverse Proxy or as an Multi-Upstream Reverse Proxy? (S/Single | M/Multi) " REPLY
            case "${REPLY,,}" in
              [sS]|[sS][iI][nN][gG][lL][eE])
                  echo "Grabbing Stable build dependencies.."
                    proxy_default
                    custom_errors
                    ssldev
                ;;
              [mM]|[mM][uU][lL][tT][iI])
                  echo "Grabbing Mainline build dependencies.."
                    proxy_upstream
                    custom_errors
                    ssldev
                ;;
              *)
                echo "Invalid response. You okay?"
                ;;
          esac

          ;;
      2)
        echo "Grabbing Mainline build dependencies.."
          mainline
          upkeep
          nginx_default

          # NGINX Proxy Sub Arg
          read -r -p "Do you want to setup NGINX as a single base Reverse Proxy or as an Multi-Upstream Reverse Proxy? (S/Single | M/Multi) " REPLY
            case "${REPLY,,}" in
              [sS]|[sS][iI][nN][gG][lL][eE])
                  echo "Grabbing Stable build dependencies.."
                    proxy_default
                    custom_errors
                    ssldev
                ;;
              [mM]|[mM][uU][lL][tT][iI])
                  echo "Grabbing Mainline build dependencies.."
                    proxy_upstream
                    custom_errors
                    ssldev
                ;;
              *)
                echo "Invalid response. You okay?"
                ;;
          esac

          ;;
    esac
clear

# Close Arg for Main Statement.
      ;;
    [nN]|[nN][oO])
      echo "You have said no? We cannot work without your permission!"
      ;;
    *)
      echo "Invalid response. You okay?"
      ;;
esac

read -r -p "Would you like to setup the sysctl.conf to harden the security of the host box? (Y/N) " REPLY
  case "${REPLY,,}" in
    [yY]|[yY][eE][sS])
        echo "Setting up sysctl.conf rules. Hold tight.."
          wget -O /etc/sysctl.conf https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/sysctl.conf
          ;;
    [nN]|[nN][oO])
      echo "You have said no? We cannot work without your permission!"
      ;;
    *)
    echo "Invalid response. You okay?"
    ;;
  esac

  # PHP Arg main
  read -r -p "Do you want to install and setup PHP? (Y/N) " REPLY
    case "${REPLY,,}" in
      [yY]|[yY][eE][sS])
        HEIGHT=20
        WIDTH=120
        CHOICE_HEIGHT=4
        BACKTITLE="NGINE"
        TITLE="PHP Branch Builds"
        MENU="Choose one of the following Build options:"

        OPTIONS=(1 "5.6"
                 2 "7.1"
                 3 "7.2"
                 4 "7.3")

        CHOICE=$(dialog --clear \
                        --backtitle "$BACKTITLE" \
                        --title "$TITLE" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${OPTIONS[@]}" \
                        2>&1 >/dev/tty)


  # Attached Arg for dialogs $CHOICE output
      case $CHOICE in
        1)
          echo "Installing PHP 5.6, and its modules.."
            phpdev
            upkeep
              apt install php5.6 php5.6-fpm php5.6-cli php5.6-common php5.6-curl php5.6-mbstring php5.6-mysql php5.6-xml
              sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/5.6/fpm/pool.d/www.conf
              sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/5.6/fpm/pool.d/www.conf
              sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/5.6/fpm/php.ini
              sed -i 's/phpx.x-fpm.sock/php5.6-fpm.sock/g' /etc/nginx/conf.d/nginx-proxy.conf
              service php5.6-fpm restart
              service php5.6-fpm status
              service nginx restart
              ps aux | grep -v root | grep php-fpm | cut -d\  -f1 | sort | uniq
            ;;
        2)
          echo "Installing PHP 7.1, and its modules.."
            phpdev
            upkeep
              apt install php7.1 php7.1-fpm php7.1-cli php7.1-common php7.1-curl php7.1-mbstring php7.1-mysql php7.1-xml
              sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.1/fpm/pool.d/www.conf
              sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.1/fpm/pool.d/www.conf
              sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.1/fpm/php.ini
              sed -i 's/phpx.x-fpm.sock/php7.1-fpm.sock/g' /etc/nginx/conf.d/nginx-proxy.conf
              service php7.1-fpm restart
              service php7.1-fpm status
              service nginx restart
              ps aux | grep -v root | grep php-fpm | cut -d\  -f1 | sort | uniq
            ;;
        3)
          echo "Installing PHP 7.2, and its modules.."
            phpdev
            upkeep
              apt install php7.2 php7.2-fpm php7.2-cli php7.2-common php7.2-curl php7.2-mbstring php7.2-mysql php7.2-xml
              sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.2/fpm/pool.d/www.conf
              sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.2/fpm/pool.d/www.conf
              sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini
              sed -i 's/phpx.x-fpm.sock/php7.2-fpm.sock/g' /etc/nginx/conf.d/nginx-proxy.conf
              service php7.2-fpm restart
              service php7.2-fpm status
              service nginx restart
              ps aux | grep -v root | grep php-fpm | cut -d\  -f1 | sort | uniq
            ;;
        4)
          echo "Installing PHP 7.3, and its modules.."
            phpdev
            upkeep
             apt install php7.3 php7.3-fpm php7.3-cli php7.3-common php7.3-curl php7.3-mbstring php7.3-mysql php7.3-xml
             sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.3/fpm/pool.d/www.conf
             sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.3/fpm/pool.d/www.conf
             sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.3/fpm/php.ini
             sed -i 's/phpx.x-fpm.sock/php7.3-fpm.sock/g' /etc/nginx/conf.d/nginx-proxy.conf
             service php7.3-fpm restart
             service php7.3-fpm status
             service nginx restart
             ps aux | grep -v root | grep php-fpm | cut -d\  -f1 | sort | uniq
            ;;
      esac
  clear

  # Close Arg for Main Statement.
        ;;
      [nN]|[nN][oO])
        echo "You have said no? We cannot work without your permission!"
        ;;
      *)
        echo "Invalid response. You okay?"
        ;;
  esac


  read -r -p "Do you want to setup NGINX to get a 100% Qualys SSL Rating? (Y/Yes | N/No) " REPLY
    case "${REPLY,,}" in
      [yY]|[yY][eE][sS])
            sslqualy
        ;;
      [nN]|[nN][oO])
          echo "You have said no? We cannot work without your permission!"
        ;;
      *)
        echo "Invalid response. You okay?"
        ;;
  esac
