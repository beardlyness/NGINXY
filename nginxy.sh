#!/usr/bin/env bash
#===============================================================================================================================================
# (C) Copyright 2018 NGINXY a project under the Crypto World Foundation (https://cryptoworld.is).
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
# contributors     :Beardlyness
# date             :04-21-2018
# version          :0.0.4 Alpha
# os               :Debian
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

# Grabbing info on active machine.
    flavor=`lsb_release -cs`
    system=`lsb_release -i | grep "Distributor ID:" | sed 's/Distributor ID://g' | sed 's/["]//g' | awk '{print tolower($1)}'`

#START

# Checking for multiple "required" pieces of software.
    if
      echo -e "\033[92mPerforming upkeep of system packages..\e[0m"
        upkeep

      echo -e "\033[92mChecking software list..\e[0m"

    [ ! -x  /usr/bin/lsb_release ] || [ ! -x  /usr/bin/wget ] || [ ! -x  /usr/bin/apt-transport-https ] || [ ! -x  /usr/bin/dirmngr ] || [ ! -x  /usr/bin/ca-certificates ] ; then

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
  fi

# NGINX Arg main
  read -r -p "Do you want to setup NGINX as a Reverse Proxy? (Y/N) " REPLY
    case "${REPLY,,}" in
      [yY]|[yY][eE][sS])
          echo deb http://nginx.org/packages/$system/ $flavor nginx > /etc/apt/sources.list.d/deb.nginx.org.list
          echo deb-src http://nginx.org/packages/$system/ $flavor nginx >> /etc/apt/sources.list.d/deb.nginx.org.list
            wget -4 https://nginx.org/keys/nginx_signing.key
            apt-key add nginx_signing.key
          echo "Performing upkeep.."
            upkeep
          echo "Installing NGINX.."
            apt-get install nginx
            service nginx status
          echo "Raising limit of workers.."
            ulimit -n 65536
            ulimit -a
          echo "Setting up Security Limits.."
            cat > /etc/security/limits.conf <<EOF
# This is added for Open File Limit Increase
*               hard    nofile          199680
*               soft    nofile          65535

root            hard    nofile          65536
root            soft    nofile          32768

# This is added for Nginx User
nginx           hard    nofile          199680
nginx           soft    nofile          65535

* soft nofile 65536
* hard nofile 65536
EOF

        echo "Setting up background NGINX workers.."
          cat > /etc/default/nginx <<EOF
# Defaults for nginx initscript
# sourced by /etc/init.d/nginx

# Additional options that are passed to nginx
DAEMON_ARGS=""
ULIMIT="-n 65535"
EOF
          echo "Restarting NGINX daemon"
            service nginx restart
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

            echo "Restarting Networking on host box.."
              service networking restart && service networking status

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

      read -r -p "Would you like to setup the sysctl.conf to harden the security of the host box? (Y/N) " REPLY
        case "${REPLY,,}" in
          [yY]|[yY][eE][sS])
              echo "Setting up sysctl.conf rules. Hold tight.."

                cat > /etc/sysctl.conf <<EOF
kernel.printk = 4 4 1 7
kernel.panic = 10
kernel.sysrq = 0
kernel.shmmax = 4294967296
kernel.shmall = 4194304
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
vm.swappiness = 20
vm.dirty_ratio = 80
vm.dirty_background_ratio = 5
fs.file-max = 2097152
net.core.netdev_max_backlog = 262144
net.core.rmem_default = 31457280
net.core.rmem_max = 67108864
net.core.wmem_default = 31457280
net.core.wmem_max = 67108864
net.core.somaxconn = 65535
net.core.optmem_max = 25165824
net.ipv4.neigh.default.gc_thresh1 = 4096
net.ipv4.neigh.default.gc_thresh2 = 8192
net.ipv4.neigh.default.gc_thresh3 = 16384
net.ipv4.neigh.default.gc_interval = 5
net.ipv4.neigh.default.gc_stale_time = 120
net.netfilter.nf_conntrack_max = 10000000
net.netfilter.nf_conntrack_tcp_loose = 0
net.netfilter.nf_conntrack_tcp_timeout_established = 1800
net.netfilter.nf_conntrack_tcp_timeout_close = 10
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 10
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 20
net.netfilter.nf_conntrack_tcp_timeout_last_ack = 20
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 20
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 20
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 10
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.route.flush = 1
net.ipv4.route.max_size = 8048576
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_congestion_control = htcp
net.ipv4.tcp_mem = 65536 131072 262144
net.ipv4.udp_mem = 65536 131072 262144
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.udp_rmem_min = 16384
net.ipv4.tcp_wmem = 4096 87380 33554432
net.ipv4.udp_wmem_min = 16384
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 400000
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_ecn = 2
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 10
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 1
EOF

                ;;
          [nN]|[nN][oO])
            echo "You have said no? We cannot work without your permission!"
            ;;
          *)
          echo "Invalid response. You okay?"
          ;;
        esac
