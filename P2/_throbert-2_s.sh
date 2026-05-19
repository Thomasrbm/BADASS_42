#!/bin/sh


ip link set eth0 up
ip addr add 10.0.0.2/30 dev eth0

ip link add name br0 type bridge
ip link set br0 up

ip link add vxlan10 type vxlan id 10 remote 10.0.0.1 dstport 4789 dev eth0
ip link set vxlan10 up
ip link set vxlan10 master br0

ip link set eth1 up
ip link set eth1 master br0
