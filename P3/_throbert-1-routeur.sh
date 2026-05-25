#!/bin/sh

ip link set eth0 up
ip addr add 10.0.14.1/30 dev eth0

ip link set lo up
ip addr add 1.1.1.1/32 dev lo


ip link add name br0 type bridge
ip link set br0 up

# no learning

ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.1 \
    nolearning
ip link set vxlan10 up
ip link set vxlan10 master br0

# desac le forward db pour laisser bgp evpn faire le taff
# sinon 
bridge link set dev vxlan10 learning off

# desac le broadcast de base a tout les vtep
# pour passer par bgp evpn
# sinon
bridge link set dev vxlan10 neigh_suppress on


ip link set eth1 up
ip link set eth1 master br0

# ospf routeur = id ce routeur avec l ip lo
# fait tourner ospf sur le eth0
# annonce le lo sur le RR et donc dit sont lo a tous les voisins
# passive = ne fait rien, envoit pas de paquets

# router bgp 65000
# prend un Id AS private (donc interne AS)
# desactive bgp classique, car on fait EVPN (pas l3 mais 2 - l3)
# prend le voisin proche comme RR et soure (plus stable que prendr eth0 en source)

# address-family l2vpn evpn active le evpn
# prend voisin evpn .4
# et previent tous les vni du RR que tu existe 

vtysh <<'EOF'
configure terminal

router ospf
 ospf router-id 1.1.1.1
 network 10.0.14.0/30 area 0
 network 1.1.1.1/32   area 0
 passive-interface lo
exit

router bgp 65000
 bgp router-id 1.1.1.1
 no bgp default ipv4-unicast
 neighbor 1.1.1.4 remote-as 65000
 neighbor 1.1.1.4 update-source lo

 address-family l2vpn evpn
  neighbor 1.1.1.4 activate
  advertise-all-vni
 exit-address-family
exit

end
write memory
EOF
