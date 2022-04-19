#!/bin/bash

# IPTABLES設定用スクリプト
# Last Modified: 2022/04/19 21:00

#####################################

# IPアドレスの設定
grobalip="[your grobal IP address]"
grobalipv6="[your grobal IP address(IPv6)]"
gateway="[gateway IP address]"
server1="[server IP address]"
server2="[server IP address]"

# 全体の設定(v4&v6)

iptables -F INPUT
iptables -F OUTPUT
iptables -F FORWARD

ip6tables -F INPUT
ip6tables -F OUTPUT
ip6tables -F FORWARD
ip6tables -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT

# ループバックの設定

iptables -I INPUT -i lo -j ACCEPT
iptables -I OUTPUT -o lo -j ACCEPT

ip6tables -I INPUT -i lo -j ACCEPT
ip6tables -I OUTPUT -o lo -j ACCEPT

# セッションが確立された通信の設定

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# パケットの転送に関する設定

iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# IPアドレス・ポート別の設定
# コメントイン、アウトで適宜設定

# WAN2VPN-Client
# WAN側からのアクセスをローカルに転送
# 1. ポートフォワード 2. 送信元をVPNサーバーに変換 3. 転送を許可
#iptables -t nat -A PREROUTING -m tcp -p tcp --dst $grovalip --dport 443 -j DNAT --to-destination $server1:443
#iptables -t nat -A POSTROUTING -m tcp -p tcp --dst $server1 --dport 443 -j SNAT --to-source $gateway
#iptables -A FORWARD -m tcp -p tcp --dst $server1 --dport 443 -j ACCEPT

# 別ポートに転送
iptables -t nat -A PREROUTING -p tcp --dport 587 -j REDIRECT --to-port 1194
iptables -t nat -A PREROUTING -p tcp --dport 465 -j REDIRECT --to-port 1194

# VPN-Server2VPNClient
# VPNサーバーへのアクセスを他のVPNクライアントに
# 1. ポートフォワード 2. 送信元をVPNサーバーに変換 3. 転送を許可
iptables -t nat -A PREROUTING -m tcp -p tcp --dst $gateway --dport 80 -j DNAT --to-destination $server2:10081
iptables -t nat -A POSTROUTING -m tcp -p tcp --dst $server2 --dport 10081 -j SNAT --to-source $gateway
iptables -A FORWARD -m tcp -p tcp --dst $server2 --dport 10081 -j ACCEPT

iptables -t nat -A PREROUTING -m tcp -p tcp --dst $gateway --dport 40003 -j DNAT --to-destination $server2:40003
iptables -t nat -A POSTROUTING -m tcp -p tcp --dst $server2 --dport 40003 -j SNAT --to-source $gateway
iptables -A FORWARD -m tcp -p tcp --dst $server2 --dport 40003 -j ACCEPT

# ポート別通信許可設定
iptables -A INPUT -p tcp --dport 24 -j ACCEPT
iptables -A INPUT -p tcp --dport 1194 -j ACCEPT
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p udp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 587 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 465 -j ACCEPT

# VPNネットワークから外部に通信するための設定
# IPマスカレードを行う
iptables -t nat -A POSTROUTING -s 10.8.0.0/255.255.0.0 -o eth0 -j MASQUERADE
iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT

# ICMPパケットの許可
iptables -A INPUT -p icmp -j ACCEPT

# IPv6の設定
ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -i tun0 -j ACCEPT

# ポート別許可設定
ip6tables -A INPUT -p udp --dport 53 -j ACCEPT
ip6tables -A INPUT -p udp --sport 53 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 24 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 1194 -j ACCEPT
ip6tables -A INPUT -p udp --dport 1194 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
ip6tables -A INPUT -p udp --dport 80 -j ACCEPT

# VPNネットワークから外部に通信するための設定
# IPマスカレードを行う
ip6tables -t nat -A POSTROUTING -s $grobalipv6/64 -o eth0 -j MASQUERADE
ip6tables -A FORWARD -i tun0 -j ACCEPT
ip6tables -A FORWARD -i tun0 -o eth0 -j ACCEPT

# ポート転送
ip6tables -t nat -A PREROUTING -p tcp --dport 587 -j REDIRECT --to-port 1194
ip6tables -t nat -A PREROUTING -p tcp --dport 465 -j REDIRECT --to-port 1194

# OpenVPNの設定
ip6tables -A INPUT -i eth0 -m state --state NEW -p udp --dport 1194 -j ACCEPT

# ICMPパケットの許可
ip6tables -I INPUT -p icmp -j ACCEPT

exit 0
