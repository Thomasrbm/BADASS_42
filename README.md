<div align="center">

# BADASS

**Bgp At Doors of Autonomous Systems is Simple — build a BGP EVPN / VXLAN data-center fabric — 42 School project.**

*GNS3 + Docker + FRRouting — from a single routed container to a spine/leaf fabric with a route reflector, OSPF underlay and MP-BGP EVPN control plane, VTEPs learning MAC addresses without flooding.*

</div>

---

## Table of contents
1. [The problem](#the-problem)
2. [Stack](#stack)
3. [P1 — GNS3 and a software router](#p1--gns3-and-a-software-router)
4. [P2 — VXLAN, static then multicast](#p2--vxlan-static-then-multicast)
5. [P3 — BGP EVPN with a route reflector](#p3--bgp-evpn-with-a-route-reflector)
6. [Usage](#usage)
7. [Defense — verification commands](#defense--verification-commands)
8. [Glossary](#glossary)

---

## The problem

A VLAN tag is 12 bits: **4 094 networks**, and all of them must live in the same Layer 2 domain. A data center with thousands of tenants spread across racks and sites needs more — and needs Layer 2 to cross a routed Layer 3 network.

**VXLAN** answers the first part: a 24-bit ID (**16 million** segments) and Ethernet frames tunneled inside UDP (port 4789), so L2 rides over any IP network.

**BGP EVPN** answers the second: instead of flooding the fabric to discover who is where, routers **advertise** MAC addresses and VTEP membership through BGP — the control plane replaces flood-and-learn.

The project builds that, step by step.

---

## Stack

| Layer | Tool | Role |
|---|---|---|
| Topology | **GNS3** | Draws the network, runs the containers, wires their interfaces |
| Nodes | **Docker** (Alpine) | One image for routers, one for hosts |
| Routing suite | **FRRouting** | `zebra` (RIB / FIB), `bgpd`, `ospfd`, `isisd`, `staticd`, `vtysh` |
| Data plane | Linux kernel | `bridge`, `vxlan` interfaces via `iproute2` |
| Capture | **Wireshark** | VXLAN, OSPF and BGP packets on the GNS3 links |

`zebra` is the conductor: each protocol daemon proposes routes, `zebra` picks the best one and programs the kernel.

---

## P1 — GNS3 and a software router

Two Docker images, loaded into GNS3:

| Image | Base | Content |
|---|---|---|
| `throbert_router` | `alpine` | FRR + `busybox-extras`, `iproute2`, `tcpdump` — daemons started by `start.sh`, then hands over to `sh` |
| `throbert_host` | `alpine` | `busybox-extras`, `iproute2`, `iputils` |

`bgpd`, `ospfd` and `isisd` running, interfaces without IP addresses: a clean router ready to be configured.

---

## P2 — VXLAN, static then multicast

```
   host-1                                                       host-2
192.168.42.1 ─eth1─┐                                      ┌─eth1─ 192.168.42.2
                   │  router-1                  router-2  │
                  br0 ── vxlan10 ─ eth0 ═══════ eth0 ─ vxlan10 ── br0
                                10.0.0.1/30   10.0.0.2/30
                        └──── VNI 10, UDP 4789 ────┘
```

Each router bridges the host port (`eth1`) with a `vxlan10` interface: frames from the host are encapsulated in UDP, sent across the underlay, decapsulated on the other side. Both hosts share `192.168.42.0/24` as if they were on the same switch.

| Mode | VTEP discovery | Config |
|---|---|---|
| **Static** | the peer is hard-coded | `ip link add vxlan10 type vxlan id 10 remote 10.0.0.2 dstport 4789 dev eth0` |
| **Multicast** | every VTEP joins a group, BUM traffic goes to it | `… id 10 group 239.1.1.1 dstport 4789 dev eth0 ttl 16` |

Static scales badly (every new VTEP means editing every other one). Multicast fixes that, but requires multicast routing in the underlay — which P3 removes entirely.

---

## P3 — BGP EVPN with a route reflector

```
                           ┌──────────────────────┐
                           │  router-4  RR        │
                           │  lo 1.1.1.4          │
                           │  AS 65000            │
                           └──┬────────┬───────┬──┘
                   10.0.14.0/30   10.0.24.0/30   10.0.34.0/30
                              │        │       │
                ┌─────────────┘        │       └─────────────┐
       ┌────────┴───────┐   ┌──────────┴─────┐   ┌───────────┴────┐
       │ router-1 VTEP  │   │ router-2 VTEP  │   │ router-3 VTEP  │
       │ lo 1.1.1.1     │   │ lo 1.1.1.2     │   │ lo 1.1.1.3     │
       │ br0 + vxlan10  │   │ br0 + vxlan10  │   │ br0 + vxlan10  │
       └────────┬───────┘   └──────────┬─────┘   └───────────┬────┘
            host-1                 host-2                 host-3
        192.168.42.1           192.168.42.2           192.168.42.3
```

Three layers, each with one job:

| Plane | Protocol | Does |
|---|---|---|
| **Underlay** | OSPF area 0, point-to-point links | Makes every loopback (`1.1.1.x/32`) reachable |
| **Control plane** | iBGP AS 65000, `l2vpn evpn` family, peering between loopbacks | Advertises VTEPs and MAC addresses |
| **Data plane** | VXLAN VNI 10 | Carries the host frames |

**Route reflector.** In iBGP every router must peer with every other: *n(n-1)/2* sessions — 6 for 4 routers, 45 for 10. Router-4 is a **route reflector**: each VTEP peers only with it, and it reflects routes to the others (`neighbor LEAVES route-reflector-client`, through a peer group).

**EVPN route types.**

| Type | Sent when | Says |
|---|---|---|
| **Type 3** — Inclusive Multicast | at startup, by every VTEP | *"I am VTEP 1.1.1.1 and I serve VNI 10"* — builds the flood list, no multicast underlay needed |
| **Type 2** — MAC/IP | as soon as a host talks | *"MAC aa:bb:… sits behind VTEP 1.1.1.1"* — other VTEPs install it directly |

This is why the VTEPs are configured with **`nolearning`** and **`neigh_suppress on`**: the data plane no longer learns by flooding, BGP tells it where each MAC lives.

```sh
# on a VTEP
ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.1 nolearning
bridge link set dev vxlan10 learning off
bridge link set dev vxlan10 neigh_suppress on
```

```
router bgp 65000
 no bgp default ipv4-unicast
 neighbor 1.1.1.4 remote-as 65000
 neighbor 1.1.1.4 update-source lo
 address-family l2vpn evpn
  neighbor 1.1.1.4 activate
  advertise-all-vni
```

---

## Usage

```sh
cd P3
make                    # build throbert_router and throbert_host
make gns3               # open GNS3, load P3.gns3project, start the nodes
./deploy.sh             # configure the RR first, then the three VTEPs
./deploy_hosts.sh       # give the hosts their addresses
./clean.sh              # reset
make clean              # stop GNS3 containers, remove the images
```

`deploy.sh` finds each GNS3 container by name, `docker cp`s its script and runs it. Stuck GNS3: `pkill -9 -f gns3`.

---

## Defense — verification commands

```sh
# VNI of the tunnel — static shows `remote`, multicast shows `group`
ip -d link show vxlan10 | grep vxlan

# Routing table and OSPF underlay
vtysh -c "show ip route"

# EVPN routes: Type 3 before any host is up
vtysh -c "show bgp l2vpn evpn route"
#   *>i [3]:[0]:[32]:[1.1.1.1]   RT:65000:10

# Type 2 appears as soon as a host is started — with no IP configured on it
vtysh -c "show bgp l2vpn evpn route type 2"
```

Wireshark filters on the GNS3 links: `vxlan`, `ospf`, `bgp`, `ip.dst == 239.1.1.1` (P2 multicast: the request goes to the group, the reply comes back unicast).

---

## Glossary

| Term | Meaning |
|---|---|
| **VTEP** | VXLAN Tunnel End Point — the router that encapsulates / decapsulates |
| **VNI** | VXLAN Network Identifier — the 24-bit segment ID (here `10`) |
| **Underlay / overlay** | the routed IP network / the virtual L2 carried over it |
| **BUM** | Broadcast, Unknown unicast, Multicast — the traffic that must be flooded |
| **RR** | Route Reflector — breaks the iBGP full-mesh requirement |
| **AS** | Autonomous System — `65000` is a private ASN |
| **RT** | Route Target — `65000:10`, tags which VNI a route belongs to |

Detailed notes (in French) live in [`DOC/`](DOC/): BGP, route reflection, IS-IS levels, EVPN vs MPLS, type 2/3 routes, L2-over-L3 tunnels.

---

<div align="center">

*Built by **thomasrbm** — 42 School*

</div>
