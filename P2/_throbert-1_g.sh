#!/bin/sh

# meme chose version groupe multicast

# au lieu d avoir un ip par routeur tas une ip multicast et tu envoit a tous les VTEP (vttep = routeur) en meme temps

# group 239.1.1.1
# une adresse, en statique faudrait reecrite chaque adresse.

ip link set eth0 up
ip addr add 10.0.0.1/30 dev eth0

ip link add name br0 type bridge
ip link set br0 up


ip link add vxlan10 type vxlan \
    id 10 \
    group 239.1.1.1 \
    dstport 4789 \
    dev eth0 \
    ttl 16


ip link set vxlan10 up
ip link set vxlan10 master br0

ip link set eth1 up
ip link set eth1 master br0

