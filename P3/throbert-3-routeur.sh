#!/bin/sh

# VTEP 3
# eth0 -> RR router-4 (10.0.34.0/30)
# eth1 -> host-3 (dans br0)

ip link set lo up
ip addr flush dev lo
ip addr add 1.1.1.3/32 dev lo

ip link set eth0 up
ip addr flush dev eth0
ip addr add 10.0.34.1/30 dev eth0

ip link del br0 2>/dev/null; ip link add name br0 type bridge
ip link set br0 up

ip link del vxlan10 2>/dev/null
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.3 \
    nolearning
ip link set vxlan10 up
ip link set vxlan10 master br0

bridge link set dev vxlan10 learning off
bridge link set dev vxlan10 neigh_suppress on

ip link set eth1 up
ip link set eth1 master br0

vtysh <<'EOF'
configure terminal

interface eth0
 ip ospf mtu-ignore
 ip ospf network point-to-point
exit

router ospf
 ospf router-id 1.1.1.3
 network 10.0.34.0/30 area 0
 network 1.1.1.3/32   area 0
 passive-interface lo
exit

router bgp 65000
 bgp router-id 1.1.1.3
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
