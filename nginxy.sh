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
# date             :03-22-2019
# version          :0.0.8 Alpha
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
    apt-get update -y
    apt-get dist-upgrade -y
    apt-get clean -y
  }

  # Setting up different NGINX branches to prep for install
    function stable(){
        echo deb http://nginx.org/packages/$system/ $flavor nginx > /etc/apt/sources.list.d/$flavor.nginx.stable.list
        echo deb-src http://nginx.org/packages/$system/ $flavor nginx >> /etc/apt/sources.list.d/$flavor.nginx.stable.list
          wget https://nginx.org/keys/nginx_signing.key
          apt-key add nginx_signing.key
      }

    function mainline(){
        echo deb http://nginx.org/packages/mainline/$system/ $flavor nginx > /etc/apt/sources.list.d/$flavor.nginx.mainline.list
        echo deb-src http://nginx.org/packages/mainline/$system/ $flavor nginx >> /etc/apt/sources.list.d/$flavor.nginx.mainline.list
          wget https://nginx.org/keys/nginx_signing.key
          apt-key add nginx_signing.key
      }

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
      echo "Restarting NGINX daemon"
        service nginx restart
    }

#START

# Checking for multiple "required" pieces of software.
    if
      echo -e "\033[92mPerforming upkeep of system packages.. \e[0m"
        upkeep
      echo -e "\033[92mChecking software list..\e[0m"

      [ ! -x  /usr/bin/lsb_release ] || [ ! -x  /usr/bin/wget ] || [ ! -x  /usr/bin/apt-transport-https ] || [ ! -x  /usr/bin/dirmngr ] || [ ! -x  /usr/bin/ca-certificates ] || [ ! -x  /usr/bin/dialog ] ; then

        echo -e "\033[92mlsb_release: checking for software..\e[0m"
        echo -e "\033[34mInstalling lsb_release, Please Wait...\e[0m"
          apt-get install lsb-release

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
        echo "Performing upkeep.."
          upkeep
          nginx_default
          ;;
      2)
        echo "Grabbing Mainline build dependencies.."
          mainline
        echo "Performing upkeep.."
          upkeep
          nginx_default
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

  read -r -p "Do you wish to setup IPTable rules to harden the security of the host box? (Y/N) " REPLY
    case "${REPLY,,}" in
      [yY]|[yY][eE][sS])
          echo "Setting up IPTable rules. Hold tight.."

          echo "### 1: Drop invalid packets ###"
          /sbin/iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

          echo "### 2: Drop TCP packets that are new and are not SYN ###"
          /sbin/iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

          echo "### 3: Drop SYN packets with suspicious MSS value ###"
          /sbin/iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP

          echo "### 4: Block packets with bogus TCP flags ###"
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
          /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

          echo "### 5: Block spoofed packets ###"
          /sbin/iptables -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP
          /sbin/iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP
          /sbin/iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP
          /sbin/iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP
          /sbin/iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP
          /sbin/iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP
          /sbin/iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP
          /sbin/iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP
          /sbin/iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP

          echo "### 6: Drop ICMP ###"
          /sbin/iptables -t mangle -A PREROUTING -p icmp -j DROP

          echo "### 7: Drop fragments in all chains ###"
          /sbin/iptables -t mangle -A PREROUTING -f -j DROP

          echo "### 8: Limit connections per source IP ###"
          /sbin/iptables -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset

          echo "### 9: Limit RST packets ###"
          /sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
          /sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP

          echo "### 10: Limit new TCP connections per second per source IP ###"
          /sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
          /sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP

          echo "### 11: Limit new TCP direct connections ###"
          /sbin/iptables -I INPUT -p tcp --dport 80 -i eth0 -m state --state NEW -m recent --set
          /sbin/iptables -I INPUT -p tcp --dport 80 -i eth0 -m state --state NEW -m recent   --update --seconds 60 --hitcount 50 -j DROP

          echo "Showing IPTable rules set on host box.."
            iptables -S
          ;;
        [nN]|[nN][oO])
          echo "You have said no? We cannot work without your permission!"
          ;;
        *)
          echo "Invalid response. You okay?"
          ;;
esac
