#!/bin/sh


# link = active interface (par defaut on a rien )
ip link set eth0 up


# addr add =  assigne addresse a interface (dev pour device puis nom interface)
# tout pour cette ip sera listen ici.
ip addr add 192.168.42.1/24 dev eth0
