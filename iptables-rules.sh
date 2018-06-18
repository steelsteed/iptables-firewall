#!/bin/bash
#Copyright (C) 2006-2018 James Anderson.  All rights reserved.
#Licensed under the MIT License.  See LICENSE file for more info.

IPTABLES=/sbin/iptables

INET_INTERFACE=eth0

# Clear the filter table
$IPTABLES -t filter -F
$IPTABLES -t filter -X
$IPTABLES -t filter -P INPUT ACCEPT
$IPTABLES -t filter -P FORWARD ACCEPT
$IPTABLES -t filter -P OUTPUT ACCEPT 

# Clear the nat table
$IPTABLES -t nat -F
$IPTABLES -t nat -X
$IPTABLES -t nat -P PREROUTING ACCEPT
$IPTABLES -t nat -P POSTROUTING ACCEPT
$IPTABLES -t nat -P OUTPUT ACCEPT

# Clear the mangle table
$IPTABLES -t mangle -F
$IPTABLES -t mangle -X
$IPTABLES -t mangle -P PREROUTING ACCEPT 
$IPTABLES -t mangle -P INPUT ACCEPT
$IPTABLES -t mangle -P FORWARD ACCEPT
$IPTABLES -t mangle -P OUTPUT ACCEPT
$IPTABLES -t mangle -P POSTROUTING ACCEPT

################################################################################
# INPUT rules
################################################################################

$IPTABLES -A INPUT -p udp -i $INET_INTERFACE --sport 53 --dport 1024:65535 -j ACCEPT	#dns
$IPTABLES -A INPUT -p udp -m udp --dport 123 -m state --state NEW -j ACCEPT	#ntp

# Accept everything from localhost.localdomain
$IPTABLES -t filter -A INPUT -i lo -s 127.0.0.1 -j ACCEPT

# For now, allow all ICMP
$IPTABLES -t filter -A INPUT -p ICMP -j ACCEPT

# Ports open to the world
#22 is for ssh, 80 for http, 443 for https
$IPTABLES -t filter -A INPUT -p TCP -i $INET_INTERFACE -m multiport --dports 22,80,443 -j ACCEPT

$IPTABLES -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPTABLES -t filter -A INPUT -j DROP

################################################################################
# OUTPUT rules
################################################################################

# Accept everything to localhost.localdomain
$IPTABLES -t filter -A OUTPUT -o lo -d 127.0.0.1 -j ACCEPT

# Ignore all DHCP
$IPTABLES -t filter -A OUTPUT -o $INET_INTERFACE -p TCP --sport 68 --dport 67 -j DROP
$IPTABLES -t filter -A OUTPUT -o $INET_INTERFACE -p UDP --sport 68 --dport 67 -j DROP
$IPTABLES -t filter -A OUTPUT -o $INET_INTERFACE -p TCP --sport 67 --dport 68 -j DROP
$IPTABLES -t filter -A OUTPUT -o $INET_INTERFACE -p UDP --sport 67 --dport 68 -j DROP

# Ignore NETBIOS
$IPTABLES -t filter -A OUTPUT -o $INET_INTERFACE -p TCP --sport 137:139 -j DROP
$IPTABLES -t filter -A OUTPUT -o $INET_INTERFACE -p TCP --dport 137:139 -j DROP
$IPTABLES -t filter -A OUTPUT -o $INET_INTERFACE -p UDP --sport 137:139 -j DROP
$IPTABLES -t filter -A OUTPUT -o $INET_INTERFACE -p UDP --dport 137:139 -j DROP



################################################################################
# Final Policies
################################################################################

$IPTABLES -t filter -P INPUT DROP
$IPTABLES -t filter -P FORWARD ACCEPT
$IPTABLES -t filter -P OUTPUT ACCEPT 

$IPTABLES -t nat -P PREROUTING ACCEPT
$IPTABLES -t nat -P POSTROUTING ACCEPT
$IPTABLES -t nat -P OUTPUT ACCEPT

$IPTABLES -t mangle -P PREROUTING ACCEPT 
$IPTABLES -t mangle -P INPUT ACCEPT
$IPTABLES -t mangle -P FORWARD ACCEPT
$IPTABLES -t mangle -P OUTPUT ACCEPT
$IPTABLES -t mangle -P POSTROUTING ACCEPT

#list the new rules
$IPTABLES -L -n

#save the iptables rules
service iptables save
systemctl restart iptables.service
