#!/bin/sh

ip link set lo up
ip addr add 1.1.1.4/32 dev lo

ip link set eth0 up
ip addr add 10.0.14.2/30 dev eth0

ip link set eth1 up
ip addr add 10.0.24.2/30 dev eth1

ip link set eth2 up
ip addr add 10.0.34.2/30 dev eth2




# met opsf en ecoute sur les 3 interface et ecoute les ip de chaque routeur 

# meme AS + desac bgp calssique pour evpn

# cree un groupe LEAVES et add tout les ip neigh dessus sur le meme AS
# la loopback .4 sera source pour parler aux autres leaves 
# neighbor LEAVES route-reflector-client = les prend en clien dpuis le .4

vtysh <<'EOF'
configure terminal

router ospf
 ospf router-id 1.1.1.4
 network 10.0.14.0/30 area 0
 network 10.0.24.0/30 area 0
 network 10.0.34.0/30 area 0
 network 1.1.1.4/32   area 0
 passive-interface lo
exit

router bgp 65000
 bgp router-id 1.1.1.4
 no bgp default ipv4-unicast

 neighbor LEAVES peer-group
 neighbor LEAVES remote-as 65000
 neighbor LEAVES update-source lo

 neighbor 1.1.1.1 peer-group LEAVES
 neighbor 1.1.1.2 peer-group LEAVES
 neighbor 1.1.1.3 peer-group LEAVES

 address-family l2vpn evpn
  neighbor LEAVES activate
  neighbor LEAVES route-reflector-client
 exit-address-family
exit

end
write memory
EOF
