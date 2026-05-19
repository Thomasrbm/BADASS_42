#!/bin/sh

ip link set eth0 up
ip addr add 192.168.42.2/24 dev eth0
