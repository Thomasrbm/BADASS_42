#!/bin/sh

# routeurs en mode statiques 

ip link set eth0 up

# 4 ip en /30
ip addr add 10.0.0.1/30 dev eth0

ip link add name br0 type bridge
ip link set br0 up

# 4789 port std pour les vx
# vx = Virtual eXtensible

# le vx s accroche sur eth0, si recoit sur ce port sait que vx donc a desencapsuler.
# et sortira aussi par la
ip link add vxlan10 type vxlan id 10 remote 10.0.0.2 dstport 4789 dev eth0


# routeur host = eth1  et routeur routeur = eth0

# met en bridge eth1 et vx
ip link set vxlan10 up
ip link set vxlan10 master br0

ip link set eth1 up
ip link set eth1 master br0
