#1. Introduction to Cloud Computing


#2 Introduction to OpenStack

#3 OpenStack Concepts

##3.1 Ethernet Bridges under Linux

Linux kernel has had the ability to turn any host with more than one network interface into a bridge. 

###3.1.1 What is bridging?
 
 
Bridging is the process of transparently connecting two networks segments together, so that packets can pass between the two as if they were a single logical network. Bridging is performed on the data link 
layer; hence it is independent of the network protocol being used - it doesn't matter if you use IP, Appletalk, Netware or any other protocol, as the bridge operates upon the raw ethernet packets. 
 
Typically, in a non-bridged situation, a computer with two network cards would be connected to a separate network on each; while the computer itself may or may not route packets between the two, in the IP realm, each network interface would have a different address and different network number. When bridging is used, however, each network segment is effectively part of the same logical network, the two network cards are logically merged into a single bridge device and devices connected to both network segments are assigned addresses from the same network address range. 
 
Only those packets that need to cross from one segment of the network to another are passed from one physical interface to the other; a bridge will learn the MAC addresses of the equipment attached to each of its segments, so that it can determine which packets need to be retransmitted. This makes bridges ideal for reducing traffic on heavy networks, by segmenting off any devices that talk to each other 
frequently. 
 
These days almost all newly deployed networks would use a dedicated bridging device called a switch. This device is effectively a network hub with a bridge segment on every port. All segments are considered to be on the same network, but traffic between two segments is not broadcast to every segment; rather, it is confined only to those two segments 
themselves.

###3.1.2 Why use bridging?
 
 
There's probably not much point using a Linux box as a dedicated bridge 
or switch; switches are now available very cheaply and are much quieter 
and considerably more power efficient than your average PC.  
 
Additionally, any interface that is part of a bridge must be in promiscuous 
mode so that it will receive packets that aren't specifically destined for it; 
this will increase the load on the machine. For this reason, it is better to 
use a dedicated machine for bridging rather than one that has other 
important functions. 
 
That said, there are many things that the Linux bridging code can do 
which isn't possible with commodity switches - bridging one of your 
ethernet networks with a ppp interface, for example, or bridging together 
a number of virtual private networks.  
 
Just recently, I had a need to be able to snoop the traffic between an 
ADSL router and a small embedded VOIP device. The router's 
functionality was quite limited, so it wasn't able to do this itself; instead, I 
grabbed a PC with Linux on it, put an extra ethernet card in it, and 
bridged the network between the router and the VOIP device. This let 
traffic flow unimpeded, and I was able to see what was passing by 
running tcpdump on the Linux box.

##3.2 Linux Bridging Support
 
 
Support for bridging has been available in stable Linux kernels from version 2.4.0 onwards. Previously, patches were available for versions 2.2, however these are no longer maintained for newer 2.2.x releases. 
 

##3.3 Kernel configuration
 
If you're using a distribution supplied kernel, chances are that you already have support for Ethernet bridges on your system. Most likely it will be compiled as a module, in which case you will need to load it before you can use it: 
 
```bash
modprobe bridge
``` 
 
If you need to recompile your kernel, you will need to set the `CONFIG_BRIDGE` option to 'y' or 'm' during the configuration stage. 
 
**Userspace Tools**

All the popular distributions have the bridging userspace tools already packaged for easy installation; under Debian, Ubuntu, Fedora, Redhat Enterprise and SuSE Linux, this package is called 'bridge-utils'. The 
package provides the 'brctl' command, which is used to control all of the 
Linux bridging capabilities discussed here. 
 
If your system doesn't have a precompiled package available, you will need to download the source from the Linux ethernet bridging sourceforge page. At the time of writing, the latest stable version available of the bridge utils package was 1.1.  
 
Compilation and installation is quite straightforward: 
 
```bash
# tar xzf bridge-utils-1.1.tar.gz 
# cd bridge-utils-1.1 
# ./configure --prefix=/usr/local 
# make 
# su 
# make install
```
 
Other than the standard GNU autoconf options, there are no special compile time directives to alter the behaviour of the bridge-utils package. 

##3.4 Creating and using bridges
 
 
For simplicity's sake, we will assume that we want to bridge together two 
ethernet networks, interfaces eth0 and eth1. Figure 1 shows a fairly basic 
network: our bridging linux box (bridge01) with two network segments, 
which have two Linux machines on each (linux01 and linux02 on the first, 
and linux03 and linux04 on the second). 
  
Before we create the bridge, we should ensure that both interfaces are 
down, and have no IP address assigned to them: 
 
```bash 
# ifconfig eth0 0 down 
# ifconfig eth1 0 down
```
 
Now, we can create the bridge interface. Here we see the use of the brctl 
'addbr' command, which adds a bridge interface named 'br0'. 
 
```bash
# brctl addbr br0
```
 
There are no restrictions on the interface name used for the bridge; any 
name can be used, as long as the system does not already have an 
interface with that name. The convention, however, is to name bridges 
br0, br1 and so forth. 
 
Once the bridge interface has been created, we can add the real ethernet 
interfaces to it as ports: 
 
```bash 
# brctl addif br0 eth0 
# brctl addif br0 eth1
```
 
That's all there is to it. At this point, we can now treat the bridge interface 
as we would any other network interface on a Linux box; so the first thing 
we can do is give it an interface and bring it up on the network: 
 
```bash 
# ifconfig br0 10.1.9.1 netmask 255.255.255.0 broadcast 10.1.9.255 up 
# ifconfig br0 #
br0 Link encap:Ethernet HWaddr 10:00:01:04:71:06  
inet addr:10.1.9.1 Bcast:10.1.9.255 Mask:255.255.255.0 
UP BROADCAST RUNNING MULTICAST MTU:1500 Metric:1 
RX packets:0 errors:0 dropped:0 overruns:0 frame:0 
TX packets:49 errors:0 dropped:0 overruns:0 carrier:0 
collisions:0 txqueuelen:0  
RX bytes:0 (0.0 b) TX bytes:9442 (9.2 KiB)
```
 
The brctl command provides a 'show' function, so that it is possible to see 
the state of bridges on the machine: 
 
```bash
 # brctl show
```
 
bridge name bridge id STP enabled interfaces 
br0 8000.100001047106 yes eth0 
eth1
 
Of note is the "bridge id". This number is used with Spanning Tree 
Protocol, which will be discussed later on. 
 
At this point, it should be possible to ping the client machines on each of 
the network segments, from the bridge: 
 
```bash
bridge01:/# ping -c 1 -n 10.1.9.2 
PING 10.1.9.2 (10.1.9.2) 56(84) bytes of data. 
64 bytes from 10.1.9.2: icmp_seq=1 ttl=64 time=20.6 ms 
.
bridge01:/# ping -c 1 -n 10.1.9.4 
PING 10.1.9.4 (10.1.9.4) 56(84) bytes of data. 
64 bytes from 10.1.9.4: icmp_seq=1 ttl=64 time=20.6 ms
```
 
It will also be possible to send traffic from one of the machines on one 
segment to a machine on the other segment: 
 
```bash 
linux01:/# ping -c 1 -n 10.1.9.5 
PING 10.1.9.5 (10.1.9.5) 56(84) bytes of data. 
64 bytes from 10.1.9.5: icmp_seq=1 ttl=64 time=20.6 ms
```
 
 
More importantly, it can be seen that for traffic between two devices on a 
single network segment, the bridge will confine the traffic to that 
segment. This can be seen by running tcpdump on, say, linux03, while 
sending ICMP packets from linux01 to linux02. 
 
 
linux03:/# tcpdump -n -i eth0 icmp 
 
linux01:/# ping -n 10.1.9.3 
PING 10.1.9.3 (10.1.9.3) 56(84) bytes of data. 
64 bytes from 10.1.9.3: icmp_seq=1 ttl=64 time=20.6 ms
 
If the bridge is working correctly, linux03 should not see any of the traffic 
between linux01 and linux02, even though they are part of the same 
logical network. 
 
On the other hand, if we were to send an ICMP packet to the broadcast 
address on the network, the bridge will pass this packet across to the 
second network segment: 
 

linux01:/# ping -c 1 -b 10.1.9.255 
WARNING: pinging broadcast address 
PING 10.1.9.255 (10.1.9.255) 56(84) bytes of data. 
64 bytes from 10.1.9.2: icmp_seq=1 ttl=64 time=0.251 ms 
 
linux03:/# tcpdump -n -i eth0 icmp 
tcpdump: listening on eth0 
19:39:48.273806 10.1.9.2 > 10.1.9.255: icmp: echo request (DF) 
19:39:48.273965 10.1.9.4 > 10.1.9.2: icmp: echo reply 
19:39:48.274582 10.1.9.5 > 10.1.9.2: icmp: echo reply

This tcpdump output shows the broadcast ICMP request from linux01, and two replies, 
one from linux03 and one from linux04. linux01 and linux02 would also have sent ICMP 
responses, as indeed would the bridge itself, since we configured it to have a broadcast 
address on this network.  
 
It is worth mentioning at this point that it is perfectly possible for the bridge to be able 
to operate without having an IP address assigned to it. If this were the case, it would 
bridge packets between the two segments as shown above, but would not actually take 
part in any network exchanges on an IP level. 
 
Using the 'showmacs' command, we can see a list of the devices on the network, along 
with the port to which they are connected: 
 
 
bridge01:/# brctl showmacs br0 
port no mac addr is local? ageing timer 
2 10:00:01:02:24:04 no 0.49 
1 10:00:01:02:95:35 no 0.98 
1 10:00:01:02:34:56 no 3.84 
2 10:00:01:03:26:02 no 9.19 
1 10:00:01:03:73:03 yes 0.00 
2 10:00:01:04:71:06 yes 0.00
 
 
This list displays the MAC addresses of the six ethernet cards connected to our bridged 
network; firstly the ethernet cards in each of our four client PCs (listed as not local) and 
then the two ethernet cards in our bridge itself (and hence, local). 
 
The Ageing Time represents the period of time since the bridge last saw a packet from a 
device with a particular MAC address. After a certain amount of time has passed, the 
bridge will purge an address from its database. This is done to handle machines that 
might change ports over a period of time (for example, a laptop computer which is 
physically moved from one location to another).  
 
The ageing timeout for a bridge can be changed with the 'setageingtime' command:  

```bash 
# brctl setageingtime br0 40
```

The above command would set a bridge to purge addresses after 40 seconds.
removing bridge ports and bridge interfaces. 
 
If you need to remove a port from a bridge, brctl provides the 'delif' 
command: 
 
```bash 
# brctl delif br0 eth1
``` 

Should you want to delete a bridge completely, then use 'delbr'. You must 
shut the interface down before you can do this, however. 
 
```bash
# ifconfig br0 down 
# brctl delbr br0 
```

##3.5 Spanning Tree Protocol  
 
Spanning Tree Protocol (STP) is used by switches to handle multiple 
bridge paths on a network. The ability to have multiple paths within a 
network handles, amongst other things, one serious flaw with our 
network as show above: the bridge has become a single point of failure. 
Should it fail, the two sides of the network will be unable to talk to one 
another.  
 
We can fix this easily by adding a second bridge, as shown in Figure 2. 
STP allows these two bridges to negotiate which will be active and which 
will be passive. The active bridge will take part in all packet transmission 
between the two segments, while the passive bridge will do nothing until 
its partner fails. 
 
STP is considerably more complex than can be covered in an introductory article such as 
this, so we will cover only the basics.

As we saw earlier, every bridge has an id associated with it; this is an eight-byte 
number, the first two bytes being the bridge priority, which we can set manually, and 
the next six bytes are the MAC address of the bridge. Under Linux, the default bridge 
priority is 32768. The bridge's MAC address is that of the lowest numbered MAC address 
of all the bridge's ports. We generally represent the bridge ID as a two part hexadecimal 
number, the bridge ID followed by the MAC address as the fractional part. For example, 
8000.100001037303 is the ID of a bridge with a priority of 32768 (8000 hex) and a MAC 
address of 10:00:01:03:73:03. 
 
In a network with multiple bridges, the bridge with the lowest bridge id will be "elected" 
to be the root bridge. The root bridge then determines a path cost for every redundant 
path in the network, and where path loops are discovered, certain bridge ports are 
placed in a "blocking" state, and these ports will no longer forward packets. 
 
STP is off by default, under Linux. You can determine whether it has been turned on or 
off using "brctl show br0", as outlined above. The state can be changed using: 
 
```bash
# brctl stp br0 on #
```
or  
```bash
# brctl stp br0 off #
```
 
To see further information about STP settings on a bridge, use the "showstp" command: 
 
```bash
bridge01# brctl showstp br0 
br0 
bridge id 8000.100001037303 
designated root 8000.100001037303 
root port 0 path cost 0 
max age 20.00 bridge max age 20.00 
hello time 2.00 bridge hello time 2.00 
forward delay 15.00 bridge forward delay 15.00 
ageing time 300.00 
hello timer 0.17 tcn timer 0.00 
topology change timer 0.00 gc timer 0.00 
flags 
.
eth0 (1) 
port id 8001 state forwarding 
designated root 8000.100001037303 path cost 100 
designated bridge 8000.100001037303 message age timer 0.00 
designated port 8001 forward delay timer 0.00 
designated cost 0 hold timer 0.00 
flags 
.
eth1 (2) 
port id 8002 state forwarding 
designated root 8000.100001037303 path cost 100 
designated bridge 8000.100001037303 message age timer 0.00 
designated port 8002 forward delay timer 0.00 
designated cost 0 hold timer 0.00 
flags
``` 
 
We can see from the above that this bridge is the root bridge for its network (see "bridge 
id" and "designated root") and hence, both of its interfaces are in a forwarding state. If 
we run the same command on the second bridge, we will see a few differences:  

 
bridge02# brctl showstp br0 
br0 
bridge id 8000.100001087423 
designated root 8000.100001037303 
root port 1 path cost 100 
max age 20.00 bridge max age 20.00 
hello time 2.00 bridge hello time 2.00 
forward delay 15.00 bridge forward delay 15.00 
ageing time 300.00 
hello timer 0.00 tcn timer 0.00 
topology change timer 0.00 gc timer 238.59 
flags 
 
 
eth1 (1) 
port id 8001 state forwarding 
designated root 8000.100001037303 path cost 100 
designated bridge 8000.100001037303 message age timer 18.63 
designated port 8001 forward delay timer 0.00 
designated cost 0 hold timer 0.00 
flags 
 
eth2 (2) 
port id 8002 state blocking 
designated root 8000.100001037303 path cost 100 
designated bridge 8000.100001037303 message age timer 18.63 
designated port 8002 forward delay timer 0.00 
designated cost 0 hold timer 0.00 
flags
 
 
This bridge has an ID of 8000.100001087423, but its designated root value shows the id 
of the other bridge. This makes sense, since only one bridge can be the master on a 
network. We also see that one of its ports is listed as blocking. This is the whole point of 
STP: it removes loops on the network. If this bridge receives any packets that need to 
be sent across to a different network segment, it will ignore them, since the other bridge 
will handle it.  
 
If, for some reason, you don't like the choice of a root master that your system has 
elected for itself, it is possible to alter the priority of one or more bridges using the 
'setbridgeprio' command. Here, we set a bridge priority of 4096 (1000 hex).  
 
```bash 
# brctl setbridgeprio br0 4096
```
 
Looking at our bridges now, we will see that the bridge id has changed. 
 
```bash
# brctl show 
bridge name bridge id STP enabled interfaces 
br0 1000.100001047106 yes eth0 
eth1
```
 
It's also possible to set a specific cost to a port. This may be required where, for 
example, a slower link has been automatically selected to be the designated port instead 
of a faster one and the operator wishes to override this. Links with lower costs will be 
selected for use, in preference to those with higher costs. 
 
```bash 
# brctl setportprio br0 eth1 50
```
 
Depending on the topology of the bridge network, this may cause some of the bridge 
ports to change their status, from "forwarding" to "blocking". While this happens, part of 
the network may become unreachable for a short period of time, but it should stabilise 
and become available again within a minute.  
 
For further information on Spanning Tree Protocol, please see the IEEE 802.1D 
specification.

##3.6	ISCSI ##


##3.7	Volume Management

#4	OpenStack 101 #


##4.1	Single Node OpenStack Installation ##


##4.2	Multi Node OpenStack Installation

#5	Quantum demystified
#6	OpenStack Hands on Lab

#7	OpenStack Networking - FlatManager and FlatDHCPManager

Over time, networking in OpenStack has been evolving from a simple, barely usable model, to one 
that aims to support full customer isolation. To address different user needs, OpenStack comes with 
a handful of "network managers". A network manager defines the network topology for a given 
OpenStack deployment. As  of the current stable "Essex" release of OpenStack, one can choose from 
three different types of network managers: FlatManager, FlatDHCPManager, VlanManager. I'll 
discuss the first two of them here. 
FlatManager and FlatDHCPManager have lots in common. They both rely on the concept of bridged 
networking, with a single bridge device. Let's consider her the example of a multi-host network; 
we'll look at a single-host use case in a subsequent post.
For each compute node, there is a single virtual bridge created, the name of which is specified in 
the Nova configuration file using this option:
flat_network_bridge=br100
All the VMs spawned by OpenStack get attached to this dedicated bridge.
 
Network bridging on OpenStack compute node
This approach (single bridge per compute node) suffers from a common known limitation of bridged 
networking: a linux bridge can be attached only to a single physical interface on the host machine 
(we could get away with VLAN interfaces here, but this is not supported by FlatDHCPManager and 
FlatManager). Because of this, there is no L2 isolation between hosts. They all share the same ARP 
broadcast domain. 
The idea behind FlatManager and FlatDHCPManager is to have one "flat" IP address pool defined 
throughout the cluster. This address space is shared among all  user instances, regardless of which 
tenant they belong to. Each tenant is free to grab whatever address is available in the pool.
FlatManager
FlatManager provides the most primitive set of operations. Its role boils down just to attaching the 
instance to the bridge on the compute node. By default, it does no IP configuration of the instance. 
This task is left for the systems administrator and can be done using some external DHCP server or 
other means.
 
FlatManager network topology

##7.1	FlatDHCPManager
FlatDHCPManager plugs  a given instance into the bridge, and on top of that provides a DHCP server to boot up from.

On each compute node:

the network bridge is given an address from the "flat" IP pool a dnsmasq DHCP server process is spawned and listens on the bridge interface IP the bridge acts as the default gateway for all the instances running on the given compute node
 
FlatDHCPManager - network topology
As for dnsmasq, FlatDHCPManager creates a static lease file per compute node to guarantee the same IP address for the instance over time. The lease file is constructed based on instance data 
from the Nova database, namely MAC, IP and hostname. The dnsmasq server is supposed to hand out addresses only to instances running locally on the compute node.  To achieve this, instance data 
to be put into DHCP lease file  are filtered by the 'host' field from the 'instances' table.  Also, the default gateway option in dnsmasq is set to the bridge's IP address. On the diagram below you san see that it will be given a different default gateway depending on which compute node the instance lands.
 
Network gateways for instances running on different compute nodes
 
Below I've shown the routing table from vm_1 and for vm_3 - each of them has a different default 
gateway:

```bash
root@vm_1:~# route -n 
Kernel IP routing table 
Destination    Gateway     Genmask Flags Metric Ref Use Iface 
0.0.0.0        10.0.0.1     0.0.0.0 UG     0   0   0 eth0
root@vm_3:~# route -n 
Kernel IP routing table 
Destination    Gateway     Genmask Flags Metric Ref Use Iface 
0.0.0.0        10.0.0.4     0.0.0.0 UG     0   0   0 eth0
```

By default, all the VMs in the "flat" network can see one another regardless of which tenant they
belong to. One can enforce instance isolation by applying the following  flag in nova.conf:
allow_same_net_traffic=False
This configures  IPtables policies to prevent any traffic between instances (even inside the same 
tenant), unless it is unblocked in a security group.
From practical standpoint, "flat" managers seem to be usable for homogenous,  relatively small, internal  corporate clouds where there are no tenants at all, or their number is very limited.  Typically, the usage scenario will be a dynamically scaled web server farm or an HPC cluster. For this purpose it is usually sufficient to have a single IP address space where IP address management is offloaded to some central DHCP server or is managed in a simple way by OpenStack's dnsmasq. On the other hand, flat networking can struggle with scalability, as all the instances share the same L2 broadcast domain.
These issues (scalability + multitenancy) are in some ways addressed by VlanManager, which will be covered in an upcoming blog posts.

#8 FlatDHCPManager - OpenStack 

Here, I will explain how FlatDHCPManager works with single-host networking. It is perhaps easier to understand; it also happens to be the default mode you get when installing OpenStack using one of the easy ways (by using the Puppetrecipes). (I will not consider FlatManager, as it is not very widely used).

##8.1	General idea
With single-host FlatDHCP, there's just one instance of nova-network; dnsmasq, typically 
running on the controller node, is shared by all the VMs.
Contrast that to multi-host FlatDHCP networking, where each compute node also hosts its 
own instance of the nova-network service, which provides the DHCP server (dnsmasq) and 
default gateway for the VMs on that node.
 
In this setup, the br100 interface and an associated physical interface eth2 on the compute 
nodes don't have an assigned IP address at all; they merely serve as an L2 interconnect 
that allows the VMs to reach nova-network and each other. Nova-network essentially 
functions as an L2 switch.
VM virtual interfaces are attached to br100 as well. The VMs have their default gateway set 
(in the guest OS configuration) to 10.0.0.1, which means that all external traffic from VMs 
is routed through the controller node. Traffic within 10.0.0.0/24 is not routed through the 
controller, however.

##8.2	Network Configuration
Let us consider an actual example:
1 controller node
2 compute nodes,

eth1 hosting the management network (the one through which compute nodes can communicate 
with the controller and nova services)
eth2 hosting the VM network (the one to which VMs will be attached).
We'll start with a look at all aspects of the network configuration on the controller and one 
of the compute nodes: before and after starting a VM.
8.3	Controller node, no VMs
The controller's network configuration looks like this (it changes very little when VMs are 
spawned):

**Interfaces**:

```bash  
openstack@controller-1:~$ ip a 
... (loopback has the metadata service on 169.254.169.254) ... 
3: eth1:  mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 1000 
    link/ether 08:00:27:9d:c4:b0 brd ff:ff:ff:ff:ff:ff 
    inet 192.168.56.200/24 brd 192.168.56.255 scope global eth1 
    inet6 fe80::a00:27ff:fe9d:c4b0/64 scope link  
       valid_lft forever preferred_lft forever 
4: eth2:  mtu 1500 qdisc pfifo_fast master br100 state UNKNOWN qlen 1000 
    link/ether 08:00:27:8f:87:fa brd ff:ff:ff:ff:ff:ff 
    inet6 fe80::a00:27ff:fe8f:87fa/64 scope link  
       valid_lft forever preferred_lft forever 
5: br100:  mtu 1500 qdisc noqueue state UP  
    link/ether 08:00:27:8f:87:fa brd ff:ff:ff:ff:ff:ff 
    inet 10.0.0.1/24 brd 10.0.0.255 scope global br100 
    inet6 fe80::7053:6bff:fe43:4dfd/64 scope link  
       valid_lft forever preferred_lft forever 
```

```bash`
openstack@compute-1:~$ cat /etc/network/interfaces 
... 
iface eth2 inet manual 
  up ifconfig $IFACE 0.0.0.0 up 
  up ifconfig $IFACE promisc
```

NOTE: 
eth2 is configured to use promiscuous mode! This is extremely important. It is configured in the 
same way on the compute nodes. Promiscuous mode allows the interface to receive packets not 
targeted to this interface's MAC address. Packets for VMs will be traveling through eth2, but 
their target MAC will be that of the VMs, not of eth2, so to let them in, we must use promiscuous 
mode.

**Bridges**:

```bash
openstack@controller-1:~$ brctl show 
bridge name bridge id   STP enabled interfaces 
br100   8000.0800278f87fa no    eth2
```

**Routes**:

```bash
openstack@controller-1:~$ route -n 
Kernel IP routing table 
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface 
0.0.0.0         192.168.56.101  0.0.0.0         UG    100    0        0 eth1 
10.0.0.0        0.0.0.0         255.255.255.0   U     0      0        0 br100 
169.254.0.0     0.0.0.0         255.255.0.0     U     1000   0        0 eth1 
192.168.56.0    0.0.0.0         255.255.255.0   U     0      0        0 eth1
```

**Dnsmasq running**:

```bash
openstack@controller-1:~$ ps aux | grep dnsmasq 
.
nobody    2729  0.0  0.0  27532   996 ?        S    23:12   0:00 /usr/sbin/dns masq --strict-order --bind-interfaces --conf-file= --domain=novalocal --pid-file=/var/lib/nova/networks/nova-br100.pid --listen-address=10.0.0.1 --except-in terface=lo --dhcp-range=10.0.0.2,static,120s --dhcp-lease-max=256 --dhcp-hosts file=/var/lib/nova/networks/nova-br100.conf --dhcp-script=/usr/bin/nova-dhcpbr 
idge --leasefile-ro 
root      2730  0.0  0.0  27504   240 ?        S    23:12   0:00 /usr/sbin/dnsmasq --strict-order --bind-interfaces --conf-file= --domain=novalocal --pid-fi le=/var/lib/nova/networks/nova-br100.pid --listen-address=10.0.0.1 --except-in terface=lo --dhcp-range=10.0.0.2,static,120s --dhcp-lease-max=256 --dhcp-hosts file=/var/lib/nova/networks/nova-br100.conf --dhcp-script=/usr/bin/nova-dhcpbridge --leasefile-ro
```

**Nova configuration file**:

```bash
openstack@controller-1:~$ sudo cat /etc/nova/nova.conf 
--public_interface=eth1 
--fixed_range=10.0.0.0/24 
--flat_interface=eth2 
--flat_network_bridge=br100 
--network_manager=nova.network.manager.FlatDHCPManager 
... (more entries omitted) ...
```

**Dnsmasq configuration file**:

```bash
openstack@controller-1:~$ cat /var/lib/nova/networks/nova-br100.conf  
(empty)
```

eth1 is the management network interface (controlled by --public_interface). The controller has address 192.168.56.200, and we have a default gateway on 192.168.56.101.

eth2 is the VM network interface (controlled by --flat_interface). As said, it functions basically as an L2 switch; it doesn't even have an IP address assigned. It is bridged with br100 (controlled by --flat_network_bridge).

br100 usually doesn't have any IP address assigned as well, but on the controller node it has dnsmasq listening on 10.0.0.1 (it is the DHCP server spawned by nova and used by VMs to get an IP address) because it's the beginning of the flat network range (--fixed_range).

The dnsmasq config (`/var/lib/nova/networks/nova-br100.conf`) is empty so far, because 
there are no VMs. Do not fear the two dnsmasq processes - they're a parent and a child, and 
only the child is doing actual work.

The interfaces eth1 and eth2 existed and were configured in this way before we installed OpenStack. OpenStack didn't take part in their configuration (though if eth2 had an assigned IP address, it would be moved to br100 - I'm not sure why that is needed).

However, interface br100 was created by nova-network on startup (the code is in `/usr/lib/python2.7/dist-packages/nova/network/linux_net.py`, method ensure_bridge; it is called from the initialization code of nova/network/l3.py - the L3 network driver; look for the words L3 and bridge in /var/log/nova/nova-network.log).

__NOTE__: 
In fact, I think that on the controller node we could do just as well without br100, directly attaching dnsmasq to eth2. However, on compute nodes br100 also bridges with VM virtual interfaces vnetX, so probably the controller is configured similarly for the sake of uniformity.

Let us also look at iptables on the controller (nova only ever touches the filter and nat tables, so we're not showing raw):

```bash
root@controller-1:/home/openstack# iptables -t filter -S 
-P INPUT ACCEPT 
-P FORWARD ACCEPT 
-P OUTPUT ACCEPT 
-N nova-api-FORWARD 
-N nova-api-INPUT 
-N nova-api-OUTPUT 
-N nova-api-local 
-N nova-filter-top 
-N nova-network-FORWARD 
-N nova-network-INPUT 
-N nova-network-OUTPUT 
-N nova-network-local 
-A INPUT -j nova-network-INPUT 
-A INPUT -j nova-api-INPUT 
-A FORWARD -j nova-filter-top 
-A FORWARD -j nova-network-FORWARD 
-A FORWARD -j nova-api-FORWARD 
-A OUTPUT -j nova-filter-top 
-A OUTPUT -j nova-network-OUTPUT 
-A OUTPUT -j nova-api-OUTPUT 
-A nova-api-INPUT -d 192.168.56.200/32 -p tcp -m tcp --dport 8775 -j ACCEPT 
-A nova-filter-top -j nova-network-local 
-A nova-filter-top -j nova-api-local 
-A nova-network-FORWARD -i br100 -j ACCEPT 
-A nova-network-FORWARD -o br100 -j ACCEPT 
-A nova-network-INPUT -i br100 -p udp -m udp --dport 67 -j ACCEPT 
-A nova-network-INPUT -i br100 -p tcp -m tcp --dport 67 -j ACCEPT 
-A nova-network-INPUT -i br100 -p udp -m udp --dport 53 -j ACCEPT 
-A nova-network-INPUT -i br100 -p tcp -m tcp --dport 53 -j ACCEPT
```

Basically, this means that incoming DHCP traffic on br100 is accepted, and forwarded traffic to/from br100 is accepted. Also, traffic to the nova API endpoint is accepted too. Other chains are empty.
There are also some rules in the nat table:

```bash
  nstack@controller-1:~$ sudo iptables -t nat -S 
-P PREROUTING ACCEPT 
-P INPUT ACCEPT 
-P OUTPUT ACCEPT 
-P POSTROUTING ACCEPT 
-N nova-api-OUTPUT 
-N nova-api-POSTROUTING 
-N nova-api-PREROUTING 
-N nova-api-float-snat 
-N nova-api-snat 
-N nova-network-OUTPUT 
-N nova-network-POSTROUTING 
-N nova-network-PREROUTING 
-N nova-network-float-snat 
-N nova-network-snat 
-N nova-postrouting-bottom 
-A PREROUTING -j nova-network-PREROUTING 
-A PREROUTING -j nova-api-PREROUTING 
-A OUTPUT -j nova-network-OUTPUT 
-A OUTPUT -j nova-api-OUTPUT 
-A POSTROUTING -j nova-network-POSTROUTING 
-A POSTROUTING -j nova-api-POSTROUTING 
-A POSTROUTING -j nova-postrouting-bottom 
-A nova-api-snat -j nova-api-float-snat 
-A nova-network-POSTROUTING -s 10.0.0.0/24 -d 192.168.56.200/32 -j ACCEPT 
-A nova-network-POSTROUTING -s 10.0.0.0/24 -d 10.128.0.0/24 -j ACCEPT 
-A nova-network-POSTROUTING -s 10.0.0.0/24 -d 10.0.0.0/24 -m conntrack ! --ctstate DNAT -j ACCEPT 
-A nova-network-PREROUTING -d 169.254.169.254/32 -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.56.200:8775 
-A nova-network-snat -j nova-network-float-snat 
-A nova-network-snat -s 10.0.0.0/24 -j SNAT --to-source 192.168.56.200 
-A nova-postrouting-bottom -j nova-network-snat 
-A nova-postrouting-bottom -j nova-api-snat
```

These rules will become more important in the coming posts on floating IPs and granting VMs access to outside world (they are responsible for masquerading traffic from the VMs as if it originated on the controller, etc.), but currently the only important rule is this one: -A nova-network-PREROUTING -d 169.254.169.254/32 -p tcp -m tcp --dport 80 -j 
DNAT --to-destination 192.168.56.200:8775. It makes the nova metadata service"listen" on the link-local address 169.254.169.254 by doing DNAT from that address to its actual bind address on the controller, 192.168.56.200:8775.

###8.4	Compute node, no VMs

Interfaces:
  
```bash
openstack@compute-1:~$ ip a 
... (localhost) ... 
2: eth1:  mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 1000 
    link/ether 08:00:27:ee:49:bd brd ff:ff:ff:ff:ff:ff 
    inet 192.168.56.202/24 brd 192.168.56.255 scope global eth1 
    inet6 fe80::a00:27ff:feee:49bd/64 scope link  
       valid_lft forever preferred_lft forever 
3: eth2:  mtu 1500 qdisc noop state DOWN qlen 1000 
    link/ether 08:00:27:15:85:17 brd ff:ff:ff:ff:ff:ff 
... (virbr0 - not used by openstack) ... 
```

```bash
openstack@compute-1:~$ cat /etc/network/interfaces 
... 
iface eth2 inet manual 
  up ifconfig $IFACE 0.0.0.0 up 
  up ifconfig $IFACE promisc
```

Note that eth2 is configured to use promiscuous mode, just as on the controller!

Uninteresting stuff:
  
```bash
openstack@compute-1:~$ brctl show 
... (only virbr0) ... 
```

```bash 
openstack@compute-1:~$ sudo iptables -S 
... (only virbr0 related stuff) ...
```

Routes:
  
```bash
openstack@compute-1:~$ route -n 
Kernel IP routing table 
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface 
0.0.0.0         192.168.56.101  0.0.0.0         UG    100    0        0 eth1 
169.254.0.0     0.0.0.0         255.255.0.0     U     1000   0        0 eth1 
192.168.56.0    0.0.0.0         255.255.255.0   U     0      0        0 eth1 
192.168.122.0   0.0.0.0         255.255.255.0   U     0      0        0 virbr0
```

We see that the compute node, just as the controller node, has two interfaces: eth1 for the 
management network (192.168.56.202, routed through the external DHCP server 
192.168.56.101) and eth2 for the VM network (no IP address). It doesn't have a bridge 
interface yet, because nova-network is not running here and no VMs have been started, so 
the "L3 driver", mentioned before, has not been initialized yet.
All of this configuration was also done before installing openstack.
The peculiar thing about the compute node is that there's an entry for 169.254.0.0/16 - 
that's for the nova metadata service (which is part of nova-api and is running on the 
controller node, "listening", with the help of an iptables rule, on 169.254.169.254, while 
actually listening on 192.168.56.200:8775). The 169.254.x.x subnet is reserved in the IPv4 
protocol for link-local addresses. This entry is present here to avoid routing traffic to the 
metadata service through the default gateway (as link-local traffic must not be routed at all, 
only switched).

###8.5	Starting a VM
Now let's fire up a VM!
  
```bash
openstack@controller-1:~$ nova boot --image cirros --flavor 1 cirros 
... 
openstack@controller-1:~$ nova list 
+--------------------------------------+--------+--------+----------------------+ 
|                  ID                  |  Name  | Status |       Networks       | 
+--------------------------------------+--------+--------+----------------------+ 
| 5357143d-66f5-446c-a82f-86648ebb3842 | cirros | BUILD  | novanetwork=10.0.0.2 | 
+--------------------------------------+--------+--------+----------------------+ 
... 
openstack@controller-1:~$ nova list 
+--------------------------------------+--------+--------+----------------------+ 
|                  ID                  |  Name  | Status |       Networks       | 
+--------------------------------------+--------+--------+----------------------+ 
| 5357143d-66f5-446c-a82f-86648ebb3842 | cirros | ACTIVE | novanetwork=10.0.0.2 | 
+--------------------------------------+--------+--------+----------------------+ 
openstack@controller-1:~$ ping 10.0.0.2 
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data. 
64 bytes from 10.0.0.2: icmp_req=4 ttl=64 time=2.97 ms 
64 bytes from 10.0.0.2: icmp_req=5 ttl=64 time=0.893 ms 
64 bytes from 10.0.0.2: icmp_req=6 ttl=64 time=0.909 ms
```
So, the VM was allocated IP address 10.0.0.2 (the next section will explain how it happened), booted and is pingable from the controller (interestingly, it is not supposed to be pingable from the compute node in this network mode).

__NOTE__: 
(from Piotr Siwczak): From the controller node running in single-host mode you will be always able to ping all instances as it acts as a default gateway to them (br100 on the controller has address 10.0.0.1). And by default all traffic to VMs in the same network is allowed (by iptables) unless you set --allow_same_net_traffic=false in /etc/nova/nova.conf. In this case only traffic from 10.0.0.1 will be allowed.

Now let us see how the configuration of the controller and compute node have changed.
####8.5.1	Controller node, VM created

When nova-network was creating this instance, it chose an IP address for it from the pool of free fixed IP addresses (network configuration of an instance is done in `nova/network/manager.py`, method allocate_for_instance). The first available IP turned out to be 10.0.0.2 (availability of fixed and floating IPs is stored in the Nova database). 

Then, dnsmasq was instructed to assign the VM's MAC address with the IP address 10.0.0.2.

```bash
openstack@controller-1:~$ cat /var/lib/nova/networks/nova-br100.conf  
fa:16:3e:2c:e8:ec,cirros.novalocal,10.0.0.2
```
While booting, the VM got an IP address from dnsmasq via DHCP, as is reflected in syslog:
 
```bash
openstack@controller-1:~$ grep 10.0.0.2 /var/log/syslog 
Jul 30 23:12:06 controller-1 dnsmasq-dhcp[2729]: DHCP, static leases only on 10.0.0.2, lease time 2m 
Jul 31 00:16:47 controller-1 dnsmasq-dhcp[2729]: DHCPRELEASE(br100) 10.0.0.2 fa:16:3e:5a:9b:de unknown lease 
Jul 31 01:00:45 controller-1 dnsmasq-dhcp[2729]: DHCPOFFER(br100) 10.0.0.2 fa:16:3e:2c:e8:ec  
Jul 31 01:00:45 controller-1 dnsmasq-dhcp[2729]: DHCPREQUEST(br100) 10.0.0.2 fa:16:3e:2c:e8:ec  
Jul 31 01:00:45 controller-1 dnsmasq-dhcp[2729]: DHCPACK(br100) 10.0.0.2 fa:16:3e:2c:e8:ec cirros 
Jul 31 01:01:45 controller-1 dnsmasq-dhcp[2729]: DHCPREQUEST(br100) 10.0.0.2 fa:16:3e:2c:e8:ec  
Jul 31 01:01:45 controller-1 dnsmasq-dhcp[2729]: DHCPACK(br100) 10.0.0.2 fa:16:3e:2c:e8:ec cirros
```

All other things didn't change (iptables, routes etc.).Thus: creating an instance only affects the controller'sdnsmasq configuration.

####8.5.2	Compute node, VM created
The compute node configuration changed more substantially when the VM was created.

```bash
openstack@compute-1:~$ ip a 
... (all interfaces as before) ... 
10: vnet0:  mtu 1500 qdisc pfifo_fast master br100 state UNKNOWN qlen 500 
    link/ether fe:16:3e:2c:e8:ec brd ff:ff:ff:ff:ff:ff 
    inet6 fe80::fc16:3eff:fe2c:e8ec/64 scope link  
       valid_lft forever preferred_lft forever
```

The vnet0 interface appeared. This is the virtual network interface for the VM. Its MAC address was initialized from `/var/lib/nova/instances/instance-XXXXXXXX/libvirt.xml`. You can take a look at `/var/lib/nova/instances/instance-XXXXXXXX/console.log` to see how the VM is behaving. If you see some network errors, that's a bad sign. In our case, all is fine:
  
```bash
openstack@compute-1:~$ sudo cat /var/lib/nova/instances/instance-00000009/console.log  
... 
Starting network... 
udhcpc (v1.18.5) started 
Sending discover... 
Sending select for 10.0.0.2... 
Lease of 10.0.0.2 obtained, lease time 120 
deleting routers 
route: SIOCDELRT: No such process 
adding dns 10.0.0.1 
cloud-setup: checking http://169.254.169.254/2009-04-04/meta-data/instance-id 
cloud-setup: successful after 1/30 tries: up 4.74. iid=i-00000009 
wget: server returned error: HTTP/1.1 404 Not Found 
failed to get http://169.254.169.254/latest/meta-data/public-keys 
Starting dropbear sshd: generating rsa key... generating dsa key... OK 
===== cloud-final: system completely up in 6.82 seconds ==== 
  instance-id: i-00000009 
  public-ipv4:  
  local-ipv4 : 10.0.0.2 
...
```
So, the instance also thinks it's gotten the IP address 10.0.0.2 and default gateway 10.0.0.1 (also as a DNS server). It also attempted to download a "user data" script from the metadata service at 169.254.169.254, succeeded, then tried to download the public key for the instance, but we didn't assign any (thus HTTP 404), so a new keypair was generated.

Some more changes happened to iptables:

```bash
openstack@compute-1:~$ sudo iptables -S 
-P INPUT ACCEPT 
-P FORWARD ACCEPT 
-P OUTPUT ACCEPT 
-N nova-compute-FORWARD 
-N nova-compute-INPUT 
-N nova-compute-OUTPUT 
-N nova-compute-inst-9 
-N nova-compute-local 
-N nova-compute-provider 
-N nova-compute-sg-fallback 
-N nova-filter-top 
-A INPUT -j nova-compute-INPUT 
-A FORWARD -j nova-filter-top 
-A FORWARD -j nova-compute-FORWARD 
... (virbr0 stuff omitted) ... 
-A OUTPUT -j nova-filter-top 
-A OUTPUT -j nova-compute-OUTPUT 
-A nova-compute-FORWARD -i br100 -j ACCEPT 
-A nova-compute-FORWARD -o br100 -j ACCEPT 
-A nova-compute-inst-9 -m state --state INVALID -j DROP 
-A nova-compute-inst-9 -m state --state RELATED,ESTABLISHED -j ACCEPT 
-A nova-compute-inst-9 -j nova-compute-provider 
-A nova-compute-inst-9 -s 10.0.0.1/32 -p udp -m udp --sport 67 --dport 68 -j ACCEPT 
-A nova-compute-inst-9 -s 10.0.0.0/24 -j ACCEPT 
-A nova-compute-inst-9 -j nova-compute-sg-fallback 
-A nova-compute-local -d 10.0.0.2/32 -j nova-compute-inst-9 
-A nova-compute-sg-fallback -j DROP 
-A nova-filter-top -j nova-compute-local
```

As the network driver was initialized, we got a bunch of basic compute node rules (all except for those referencingnova-compute-inst-9).

When the instance's network was initialized, we got rules saying that traffic directed to the VM at 10.0.0.2 is processed through chain nova-compute-inst-9 - accept incoming DHCP traffic and all incoming traffic from the VM subnet, drop everything else. Such a chain is created per every instance (VM).

__NOTE__: 
In this case the separate rule for DHCP traffic is not really needed - it would be accepted anyway by the rule allowing incoming traffic from 10.0.0.0/24. However, this would not be the 
case if allow_same_net_traffic were false, so this rule is needed to make sure DHCP traffic is allowed no matter what. Also, some network filtering is being done by libvirt itself, e.g. protection against ARP 
spoofing etc. We won't focus on these filters in this document (mostly because so far I've never needed them to resolve a problem), but in case you're interested, look 
for filterref in the instance's libvirt.xml file (/var/lib/nova/instances/instance-XXXXXXXX/libvirt.xml) and use the commands sudo virsh nwfilter-list, sudo virsh 
nwfilter-dumpxml to view the contents of the filters. The filters are established by code 
in nova/virt/libvirt/connection.py andfirewall.py. Their configuration resides in 
/etc/libvirt/nwfilter.

##8.6	VM guest OS network configuration
Now let us see how the network configuration looks on the VM side.
  
```bash
openstack@controller-1:~$ ssh cirros@10.0.0.2 
cirros@10.0.0.4's password:  
$ ip a 
1: lo:  mtu 16436 qdisc noqueue state UNKNOWN  
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00 
    inet 127.0.0.1/8 scope host lo 
    inet6 ::1/128 scope host  
       valid_lft forever preferred_lft forever 
2: eth0:  mtu 1500 qdisc pfifo_fast state UP qlen 1000 
    link/ether fa:16:3e:06:5c:27 brd ff:ff:ff:ff:ff:ff 
    inet 10.0.0.2/24 brd 10.0.0.255 scope global eth0 
    inet6 fe80::f816:3eff:fe06:5c27/64 scope link tentative flags 08  
       valid_lft forever preferred_lft forever 
$ route -n 
Kernel IP routing table 
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface 
0.0.0.0         10.0.0.1        0.0.0.0         UG    0      0        0 eth0 
10.0.0.0        0.0.0.0         255.255.255.0   U     0      0        0 eth0
We see that the VM has its eth0 interface assigned IP address 10.0.0.2, and that it uses 
10.0.0.1 as the default gateway for everything except 10.0.0.0/24.
```

That is all for the network configuration, congratulations if you read all the way to here! 
Now let us consider the packet flow.

##8.7	Understanding Packet Flow
In this section we'll examine how (and why) packets flow to and from VMs in this example setup. We'll consider several scenarios: how the VM gets an IP address, ping VM from controller, ping VM from compute node, ping VM from another VM.

###8.7.1	How packets flow at L2 level
We need to first consider how packets are routed in our network at the lowest level - namely ethernet packets, addressing devices by their MAC address - because we'll need 
this to understand how they flow at a higher level.
Thankfully, this is simple.
All machines (all compute nodes and the controller) are connected via the physical network fabric attached to their eth2 interface (remember that we have two physical networks in this 
setup: eth1 for the management network and eth2 for the VM network, and for security we keep them physically separate). They all have the br100 bridge connected to eth2. A bridge is 
essentially a virtual L2 switch.
Compute nodes also have the VM virtual interfaces vnetX bridged to br100. So, ethernet broadcast packets reach all the machines' eth2 and br100, as well as all the 
VM's vnetX (and consequently all the guest OS interfaces). Ethernet unicast packets flow in a similar fashion through physical switches forming this network and through the virtual switches implemented by br100 (read How LAN switches work and Linux bridge docs; further details aren't important in this context).

###8.7.2	How packets flow at L3 level
While L2 ethernet packets address devices by their MAC address, the L3 level is all about IP packets, whose endpoints are IP addresses.
To send an IP packet to address X, one finds the MAC address corresponding to X via ARP (Address Resolution Protocol) and sends an L2 packet to this MAC address.
ARP works like this: we send an L2 broadcast packet "who has IP address X?" and whoever has it, will respond to our MAC address via L2 unicast: "Hey, that's me, my MAC is Y". This 
information will be cached in the OS "ARP cache" for a while to avoid doing costly ARP lookups for each and every IP packet (you can always view the cache by typing arp -n).

When we instruct the OS to send a packet to a particular IP address, the OS also needs to determine:
Through which device to send it - this is done by consulting the routing table (type route -n). E.g. 
if there's an entry 10.0.0.0 / 0.0.0.0 / 255.255.255.0 / br100, then a packet to 10.0.0.1 will go through br100.
What source IP address to specify. This is usually the default IP address assigned to the device through which our packet is being routed. If this device doesn't have an IP assigned, the OS will 
take an IP from one of the other devices. For more details, see Source address selection in the Linux IP networking guide.

It is very important here that eth2 (the VM network) interface is in promiscuous mode, as described previously. This allows it to receive ethernet packets and forward them to the VM interfaces even though the target address of the packets is not the eth2 MAC address.

Now we're ready to understand the higher-level packet flows.


##8.8	How the VM gets an IP address
Let us look in detail what was happening when the VM was booting and getting an IP 
address from dnsmasq via DHCP.
DHCP works like this:
You send a DHCPDISCOVER packet to find a DHCP server on your local network;
A server replies with DHCPOFFER and gives you their IP address and suggests an IP address for you;
If you like the address, you send DHCPREQUEST;
The server replies with DHCPACK, confirming your right to assign yourself this IP address;
Your OS receives the DHCPACK and assigns this IP address to the interface.
So, when the VM is booting, it sends a DHCPDISCOVER UDP broadcast packet via the guest 
OS's eth0, which is connected by libvirt to the host machine's vnet0. This packet reaches 
the controller node and consequently our DHCP server dnsmasq which listens on br100, 
etc.
I won't show the tcpdump here; there's an example in the next section.

##8.9	Ping VM from controller
Let us look in detail at how it happens that ping 10.0.0.2 succeeded when ran on the 
controller (remember that 10.0.0.2 is the IP address assigned by Openstack to the VM we 
booted).

What happens when we type ping 10.0.0.2? We send a bunch of ICMP packets and wait 
for them to return. 

We consult the routing table (route -n) and find the entry "10.0.0.0 / 0.0.0.0 / 255.255.255.0 / br100″ 
which says that packets to 10.0.0.x should be sent via the br100 interface. This also means that the 
return address will be 10.0.0.1 (as it's the IP assigned to br100 on the controller).
We send an ARP broadcast request "who has IP 10.0.0.2? Tell 10.0.0.1″ through br100 (note that I had 
to manually delete the ARP cache entry with "arp -d 10.0.0.2″ to be able to demonstrate this, because it 
was already cached after the DHCP exchange mentioned in the previous section. Actually this ARP 
exchange already happened during that prior DHCP exchange, and it only happened again because I 
forced it to do so.):
  
```bash
openstack@controller-1:~$ sudo tcpdump -n -i br100 
... 
01:38:47.871345 ARP, Request who-has 10.0.0.2 tell 10.0.0.1, length 28
```

This ARP packet gets sent through br100, which is bridged with eth2 - so it is sent to eth2, from 
where it is physically broadcast to all compute nodes on the same network. In our case there's two 
compute nodes.
The first node (compute-1) receives the ARP packet on eth2, and, as it is bridged to br100 together 
with vnet0, the packet reaches the VM. Note that this does not involve iptables on the compute 
node, as ARP packets are L2 and iptables operate above that, on L3.
The VM's OS kernel sees the ARP packet "who has 10.0.0.2?" and replies to 10.0.0.1 with an ARP 
reply packet, "That's me!"It already knows the MAC address of 10.0.0.1 because it's specified in the 
ARP packet. This ARP reply packet is sent through the guest side of vnet0, gets bridged to the host 
side, then to br100 and, via eth2, lands on controller. We can see that in the tcpdump:
  
01:38:47.872036 ARP, Reply 10.0.0.2 is-at fa:16:3e:2c:e8:ec (oui Unknown), length 46
In fact, compute-2 also receives the ARP packet, but since there's no one (including VMs) to answer 
an ARP request for 10.0.0.2 there, it doesn't play any role in this interaction. Nevertheless, 
you would see an identical ARP request in a tcpdump on compute-2.
Now we know the VM's mac address. Now we send an ICMP echo-request packet:

```bash
01:38:47.872044 IP 10.0.0.1 &gt; 10.0.0.2: ICMP echo request, id 4654, seq 1, length 64
```

This successfully reaches the VM as a result of the following sequence of iptables rules firing on the 
compute node:
  
```bash
-A FORWARD -j nova-filter-top 
-A nova-filter-top -j nova-compute-local 
-A nova-compute-local -d 10.0.0.2/32 -j nova-compute-inst-9 
-A nova-compute-inst-9 -s 10.0.0.0/24 -j ACCEPT
```

This packet reaches the VM as already described, and the VM's OS replies with an ICMP echo-reply 
packet:
  
1
01:38:47.872552 IP 10.0.0.2 &gt; 10.0.0.1: ICMP echo reply, id 4654, seq 1, length 64
 
As the VM's routing table includes 10.0.0.0/24 via 0.0.0.0 dev eth0, the packet does not get routed 
through the controller and is instead sent "as is" to VM's eth0 and routed the usual way.
This concludes the roundtrip and we get a nice message:

```bash
openstack@controller-1:~$ ping 10.0.0.2 
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data. 
64 bytes from 10.0.0.2: icmp_req=1 ttl=64 time=1.33 ms
```
We would see similar tcpdumps if we did tcpdump -i eth2 or tcpdump -i 
br100 or tcpdump -i vnet0 on the compute node. They could differ only if something 
went wrong, which would be a good reason to check the routes and iptables and 
understand why, for example, a packet that exited the controller's eth2 didn't enter the 
compute node's eth2.


##8.10	Ping VM from compute node
Don't worry, this won't be as long, because the ping will fail:
  
```bash
openstack@compute-1:~$ ping 10.0.0.2 
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data. 
ping: sendmsg: Operation not permitted
This message means that the compute node is not allowed to send ICMP packets 
(prohibited by iptables). In this case, the packet travels the following path along iptables:
-A OUTPUT -j nova-filter-top 
-A nova-filter-top -j nova-compute-local 
-A nova-compute-local -d 10.0.0.2/32 -j nova-compute-inst-9 
-A nova-compute-inst-9 -j nova-compute-sg-fallback 
-A nova-compute-sg-fallback -j DROP
```

What happened is that the ACCEPT rule from nova-compute-inst-9 didn't fire, because the 
packet was going to be routed through the default gateway at eth1 and its source address 
was the one on eth1, 192.168.56.202, which is not inside 10.0.0.0/24.
Since the packet got dropped by iptables as described, it was never physically sent over the 
wire via eth1.

##8.11	Ping VM from VM
This won't be long too, as we already saw how L3 packet routing works from/to VMs.
Basically, when one VM pings another, it uses similar L2 broadcasts to know its MAC 
address, and similar L3 packet flow to route the ping request and reply. Even the sequence 
of iptables rules allowing this interaction will be the same as in the "ping from controller" 
case.

##8.12	Ping outer world from VM
If we try to ping something outside 10.0.0.0/24 from a VM, this traffic will be routed 
through the VM's default gateway, 10.0.0.1, which is on the controller. However, in the 
current setup no such ping will ever succeed, as VMs are only allowed to communicate with 
10.0.0.0/24 (though if you try, you will see the packets in tcpdump on the controller).
Giving VMs access to the outside world is a topic for a subsequent post.

##8.13	Troubleshooting


##9	VLANs

Isolating VM traffic using VLANs

Setup:
Two Physical Networks:
Data Network:  Ethernet network for VM data traffic, which will carry VLAN tagged traffic between 
VMs.  Your physical switch(es) must be capable of forwarding VLAN tagged traffic and the physical 
switch ports should be VLAN trunks (Usually this is default behavior.  Configuring your physical 
switching hardware is beyond the scope of this document).
Management Network: This network is not strictly required, but it is a simple way to give the physical host 
an IP address for remote access, since an IP address cannot be assigned directly to eth0.  
Two Physical Hosts:
Host1, Host2.  Both hosts are running Open vSwitch.  Each host has two NICs:
eth0 is connected to the Data Network.  No IP address can be assigned on eth0.
eth1 is connected to the Management Network (if necessary).   eth1 has an IP address that is used to reach 
the physical host for management.
Four VMs:

VM1,VM2 run on Host1.  VM3,VM4 run on Host2.
Each VM has a single interface that appears as a Linux device (e.g., "tap0″) on the physical host.  (Note: 
for Xen/XenServer, VM interfaces appears as Linux devices with names like "vif1.0″)
 
Goal:
Isolate VMs using VLANs on the Data Network. 
VLAN 1: VM1,VM3 
VLAN 2: VM2,VM4
Configuration:
Perform the following configuration on Host 1:
Create an OVS bridge:
ovs-vsctl add-br br0
Add eth0 to the bridge (by default, all OVS ports are VLAN trunks, so eth0 will pass all VLANs):
ovs-vsctl add-port br0 eth0
Add VM1 as an "access port" on VLAN 1:
ovs-vsctl add-port br0 tap0 tag=1
Add VM2 on VLAN 2:
ovs-vsctl add-port br0 tap1 tag=2
On Host 2, repeat the same configuration to setup a bridge with eth0 as a trunk:
ovs-vsctl add-br br0
ovs-vsctl add-port br0 eth0
Add VM3 to VLAN 1:
ovs-vsctl add-port br0 tap0 tag=1
Add VM4 to VLAN 2:
ovs-vsctl add-port br0 tap1 tag=2
Trouble-Shooting:
Ping from VM1 to VM3, this should succeed.
Ping from VM2 to VM4, this should succeed.
Ping from VM1/VM3 to VM2/VM4, this should not succeed (unless you have a router configured to 
forward between the VLANs, in which case, packets arriving at VM3 should have the source MAC 
address of the router, not of VM1).
If you have problems with this cookbook entry, please send them to the OVS discuss email list.

##10	OpenStack VLAN Networking - ##


FlatOpenstack Networking for Scalability 
and Multi-tenancy with VlanManager

VlanManager is by all means the most sophisticated networking model offered by OpenStack now. L2 scalability and inter-tenant isolation have been addressed. Nevertheless, it still has its limitations. For example, for each tenant network it relates ip pools (L3 layer) to vlans (L2 layer) (remember? - each tenant's network is identified by a 
pair of ip pool + vlan). So it is not possible to have two different tenants use the same ip addressing schemes independently in different L2 domains.
Also - vlan tag field is only 12 bits long, which tops out at only 4096 vlans. That means you can have no more than 4096 potential tenants, not that many at cloud scale.
These limitations are yet to be addressed by emerging technologies such as Quantum, the new network manager for OpenStack and software-defined networking.

In a previous post I explained the basic mode of network operation for OpenStack, namely FlatManager and its extension, FlatDHCPManager. In this post, I'll talk about VlanManager. 
While flat managers are designed for simple, small scale deployments, VlanManager is a good choice for large scale internal clouds and public clouds. As its name implies, VlanManager relies on the use of vlans ("virtual LANs"). The purpose of vlans is to partition a physical network into distinct broadcast domains (so that host groups belonging to different vlans can't see each other). 

VlanManager tries to address two main flaws of flat managers, those being

*	lack of scalability (flat managers rely on a single L2 broadcast domain across the whole OpenStack 
installation)
*	lack of proper tenant isolation (single IP pool to be shared among all the tenants)

In this post I will focus on VlanManager using multi-host network mode in OpenStack. Outside the sandbox, this is considered safer than using single-host mode, as multi-host does not suffer from the SPOF generated by running a single instance of a nova-network daemon per an entire openstack cluster. However, using VlanManager in single-host mode is in fact possible. (More about multi-host vs single-host mode can be foundhere).

###10.1	Difference between "flat" managers and VlanManager
With flat managers, the typical administrator's workflow for networking is as follows:

* Create one, large fixed ip network (typically with 16-bit netmask or less) to be shared by all tenants:

```bash
nova-manage network create --fixed_range_v4=10.0.0.0/16 --label=public
```

* Create the tenants
	Once tenants spawn their instances, all of them are assigned whatever is free in the shared IP pool.
So typically, this is how IPs are allocated their instances in this mode:

tenant_1:
tenant_2:
 
We can see tenant_1 and tenant_2 instances have landed on the same IP network, 10.0.0.0.
With VlanManager, the admin workflow changes:

*	Create a new tenant and note  its tenantID
*	Create a dedicated fixed ip network for the new tenant:
  
```bash
nova-manage network create --fixed_range_v4=10.0.1.0/24 --vlan=102  --project_id="tenantID"
```

Upon spawning, tenant's instance will automatically be assigned an IP from tenant's private IP pool.
So, compared to FlatDHCPManager, we additionally define two things for the network:
Associate the network with a given tenant (--project_id=<tenantID>). This way no one else 
than the tenant can take IPs from it.
Give this network a separate vlan (--vlan=102).

From now on, once a tenant spawns a new vm, it will automatically get the address from 
his dedicated pool. It will also be put on a dedicated vlan which OpenStack will 
automatically create and maintain. So if we created two different networks for two tenants, 
the situation will look like this:
tenant_1:
 
tenant2:
 
It can be clearly seen that tenants' instances have landed on different IP pools. But how are 
vlans supported?

How VlanManager configures networking
VlanManager does three things here:
Creates a dedicated bridge for the tenant's network on the compute node.
Creates a vlan interface on top of compute node's physical network interface eth0.
Runs and configures dnsmasq process attached to the bridge so that the tenant's instance can boot 
from it.
Let's suppose that the tenant named "t1" spawns its instance t1_vm_1. It lands on one of 
the compute nodes. This is how the network layout looks:
 
We can see that a dedicated bridge named "br102" has been created along with a vlan 
interface "vlan102". Also a dnsmasq process has been spawned and is listening on address 10.0.2.1. Once instance t1_vm_1 boots up, it receives its address from the dnsmasq based 
on a static lease (please see this previous post on the details of how dnsmasq is managed 
by OpenStack).
Now, let's assume now that tenant "t1" spawns another instance named t1_vm_2, and it happens to land on the same compute node as the instance previously created:
 
Both instances end up being attached to the same bridge, since they belong to the same tenant, and thus they are placed on the same dedicated tenant's network. They also get 
their DHCP configuration from the same dnsmasq server.
Now let's say that tenant "t2" spawns his first instance. It also lands on the same compute 
node as tenant "t1". Also, for his network, a dedicated bridge, vlan interface and dnsmasq 
are configured:
 
So it turns out that depending on the number of tenants, this is a normal situation where you have quite a large number of network bridges and dnsmasq processes, all running within a single compute node.
There's nothing wrong with this, however - OpenStack will manage all of them automatically. Unlike the case of using flat managers, here both tenants' instances reside on different bridges which are not connected to each other. This ensures traffic separation on L2 level. In case of tenant "t1", the ARP broadcasts sent over br102 and then through to vlan102 are not visible on br103 and vlan103, and vice versa.
 
##10.2	Support for tenant networks across multiple compute nodes
So far, we've talked about how this plays out on a single compute node. Most likely, you'll probably use a lot more than one compute node. Usually we want to have as many of them 
as possible. Then, likely, tenant "t1″ instances will be scattered among many compute nodes. This means that his dedicated network must also be spanned across many compute 
nodes. 

Still it will need to meet two requirements: 

*	t1′s instances residing on different physical compute nodes must communicate

t1′s network spanning multiple compute nodes must be isolated from other tenants' networks
Typically, compute nodes are connected to a network switch by a single cable. We want 
multiple tenants to share this link in a way that they don't see one another's traffic.
There is a technology that addresses this requirement called Vlan tagging. Technically, it 
extends each Ethernet frame by adding a 12-bit field called VID (Vlan ID), which bears the 
vlan number. Frames bearing an identical Vlan tag belong to a single L2 broadcast domain; 
thus devices whose traffic is tagged with the same Vlan ID can communicate.
It should be obvious, then, that one can isolate tenants' networks by tagging them with 
different Vlan IDs. 
How does this work in practice? Let us look at the above diagrams.
Traffic for tenant "t1" leaves the compute node via "vlan102″. Vlan102 is a virtual interface 
connected to eth0. Its sole purpose is to tag frames with a vlan number "102″, using the 802.1q protocol.
Traffic for tenant "t2" leaves the compute node via "vlan103″, which is tagged with vlan tag 
103. By bearing different vlan tags, "t1′s" traffic will in no way interfere with "t2's" traffic.
They are unaware of each other, even though they both use the same physical interface 
eth0 and, afterwards, the switch ports and backplane.

Next, we need to tell the switch to pass tagged traffic over its ports. This is done by putting 
a given switch port into "trunk" mode (as opposed to "access" mode, which is the default). 
In simple words, trunk allows a switch to pass VLAN-tagged frames; more information on 
vlan trunks can be found in this article. At this time, configuring the switch is the duty of 
the system administrator. Openstack will not do this automatically. Not all switches 
support vlan trunking. It's something you need to look out for prior to procuring the switch 
you'll use.
Also - if you happen to use devstack + virtualbox to experiment with VlanManager in a 
virtual environment, make sure you choose "PCNET - Fast III" as the adapter to connect 
your vlan network.
Having done this, we come to this model of communication:

The thick black line from compute nodes to the switch is a physical link (cable). On top of 
the same cable, vlan traffic tagged by both 102 and 103 is carried (red and green dashed 
lines). There is no interference in traffic (the two lines never cross).
So how does the traffic look when tenant "t1" wants to send a ping from 10.0.2.2 to 
10.0.2.5?
The packet goes from 10.0.2.2 to the bridge br102 and way up to vlan102, where it has the tag 102 
applied.
It goes past the switch which handles vlan tags. Once it reaches the second compute node, its vlan 
tag is examined.
Based on the examination, a decision is taken by compute node to put it onto vlan102 interface.
Vlan102 strips the Vlan ID field off the packet so that it can reach instances (instances don't have 
tagged interfaces).
Then it goes down the way through br102 to finally reach 10.0.2.5.
 
**Configuring VlanManager**

To configure VlanManager networking in OpenStack, put the following lines into your 
nova.conf file:
  
We point OpenStack to use VlanManager here:  

```bash
network_manager=nova.network.manager.VlanManager  
```
 
Interface on which virtual vlan interfaces will be created: 

```bash
vlan_interface=eth0  
```

The first tag number for private vlans  (in this case, vlan numbers lower than 100 can serve our internal purposes and will not be consumed by tenants): 

```bash
vlan_start=100
```

#11	Openstack hands on lab


#12	Block Storage #


#13	Image management #


#14	Object storage #


#15	OpenStack Operations

```bash
pandoc -f markdown -t latex hello.txt
```
