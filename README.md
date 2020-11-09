# deploy-openstack

Deploy OpenStack using MaaS, Kolla-OpenStack, and cephadm.

# Versions
* MAAS version: 2.8.2 (8577-g.a3e674063)
* Kolla-Ansible: < 11 (Usurri)
* Ansible: < 2.9
* CephADM: octopus

## MaaS

Please configure MaaS to:
* Have your SSH public key installed
* Have gitlabs SSH public key installed
* Ability to deploy Ubuntu 18

Each server in MaaS needs the following configuration:
* At least 2 Nics with IP's configured,
    1. (REQUIRED) One completely internal network, used for management network.  This will be referenced as your private network in our multinode file.
    2. (REQUIRED) One network which is public facing and needs to be a bridge with an IP associated with it.  This will be referenced as your public network in our multinode file.
    3. (OPTIONAL) If possible, a high speed network for use with storage/ceph, this should also be internal and seperate from public access. This will be referenced as your data network in our multinode file. This network is optional, but hightly recommended.
* The public network needs to be configured with a bridge, br0.  We have STP enabled with a 15 ms forward delay.

### **Don't have MaaS?**

To bypass the use of MaaS, make sure you have
* Ubuntu installed,
* your br0 configured on your public nic with an IP, and
* your gitlab SSH public key installed.
* Also, set `REPROVISION_SERVERS=false` variable in GitLab, so it doesn't try to access the MaaS server.

## Stages
### (OPTIONAL) Reprovision servers
This step will only occur if you have `REPROVISION_SERVERS=true` set in gitlab variables. This step will release, wait for a ready state, then begin provisioning the servers from your multinode file.  It does this by querying maas for all of the machines, and captures the machine ID based off of the IP's specified in your multinode file.

### Bootstrap Networking
This will take your br0 and create 2 virtual interfaces (veno0 & veno1) used in kolla ansible's globals file.  neutron_external_interface will be use veno1 and kolla_external_vip_interface=br0.

### (OPTIONAL) Reboot
This stage will only happen if you are not using MaaS.

### Bootstrap OpenStack
* Your kolla password and certificates will be generated here.  
* SSH access will be granted for the ubuntu and root user.  SSH access is necessary for the root due to cephadm.
* Globals file will be generated
* Your nova.conf config file will be generated here.

### Deploy Ceph and OpenStack Pull
* Cephadm will be configured to use your control[0] node and will be deployed.
    * All of your ceph volumes and keyrings will be generated in this stage.
* Kolla pre-checks and kolla pull will both run.

### Deploy OpenStack
* Kolla runs bootstrap one more time to fix issues caused by ceph,
* Kolla deploy, and
* Kolla post-deploy to generate the admin-openrc.sh file

### Post deploy OpenStack
* CirrOS will be downloaded and uploaded to OpenStack.
* Various flavors and networks will be created.

### Test Setup
* Refstack will be configured and run in the following stages.
    * `refstack-client test -c etc/tempest.conf -v --test-list "https://refstack.openstack.org/api/v1/guidelines/2020.06/tests?target=platform&type=required&alias=true&flag=false"`

## Physical Architecture

The conceptual layout of the hardware consists of the following 3 switches and N number of servers.  The public switch has internet access and you are able to SSH into.  The private switch and high speed switch is airgapped from the internet and is completely internal. These two switches could be condensed into one switch, preferrably a high speed one. Your actual layout may differ if you choose to use, for example, less switches and instead vlans or more switches for binding ports together, etc.

```
┌──────────────────
│ PUBLIC SWITCH
├──────────────────
│ PRIVATE SWITCH
├──────────────────
│ HIGH SPEED SWITCH
├──────────────────
│ SERVER 1
├──────────────────
│ SERVER 2
├──────────────────
│ SERVER 3
├──────────────────
│ SERVER N
└──────────────────
```

## Configs

Tree structure of our config files:

```
/etc/kolla/config/
├── [drwxr-xr-x ubuntu   ubuntu  ]  cinder
│   ├── [drwxr-xr-x ubuntu   ubuntu  ]  cinder-backup
│   │   ├── [-rw-rw-r-- ubuntu   ubuntu  ]  ceph.client.cinder-backup.keyring
│   │   ├── [-rw-rw-r-- ubuntu   ubuntu  ]  ceph.client.cinder.keyring
│   │   └── [-rw-r--r-- ubuntu   ubuntu  ]  ceph.conf
│   └── [drwxr-xr-x ubuntu   ubuntu  ]  cinder-volume
│       ├── [-rw-rw-r-- ubuntu   ubuntu  ]  ceph.client.cinder.keyring
│       └── [-rw-r--r-- ubuntu   ubuntu  ]  ceph.conf
├── [drwxr-xr-x ubuntu   ubuntu  ]  glance
│   ├── [-rw-rw-r-- ubuntu   ubuntu  ]  ceph.client.glance.keyring
│   └── [-rw-r--r-- ubuntu   ubuntu  ]  ceph.conf
├── [drwxr-xr-x ubuntu   ubuntu  ]  nova
│   ├── [-rw-rw-r-- ubuntu   ubuntu  ]  ceph.client.cinder.keyring
│   └── [-rw-r--r-- ubuntu   ubuntu  ]  ceph.conf
└── [-rw-rw-r-- ubuntu   ubuntu  ]  nova.conf

5 directories, 10 files
```


# multinode file
```
#public = "Internet facing IP's"
#private = "Non-Internet facing IP's"
#data = "Non-Internet facing IP's, high speed IP's used for ceph, if not available leave "" "
[control]
    [control.0]
    public = "172.16.123.23"
    private = "192.168.3.23"
    data = "10.100.3.23"
[network]
    [network.0]
    public = "172.16.123.23"
    private = "192.168.3.23"
    data = "10.100.3.23"
[storage]
    [storage.0]
    public = "172.16.123.23"
    private = "192.168.3.23"
    data = "10.100.3.23"
[compute]
    [compute.0]
    public = "172.16.123.29"
    private = "192.168.3.29"
    data = "10.100.3.29"
    [compute.1]
    public = "172.16.123.25"
    private = "192.168.3.25"
    data = "10.100.3.25"
[monitor]
    [monitor.0]
    public = ""
    private = ""
    data = ""
```

# globals file

```
Our default options are as follows:
kolla_base_distro: "centos"
kolla_install_type: "source"
openstack_release: "ussuri"
kolla_internal_vip_address: "ENO1 first three octets.250"
kolla_external_vip_address: "BR0 first 3 octets.250"
network_interface: "eno1"
kolla_external_vip_interface: "br0"
neutron_external_interface: "veno1"
kolla_enable_tls_internal: "yes"
kolla_enable_tls_external: "yes"
kolla_copy_ca_into_containers: "yes"
kolla_verify_tls_backend: "no"
kolla_enable_tls_backend: "yes"
openstack_cacert: /etc/pki/tls/certs/ca-bundle.crt
enable_cinder: "yes"
enable_cinder_backend_lvm: "no"
ceph_nova_user: "cinder"
glance_backend_ceph: "yes"
glance_backend_swift: "no"
cinder_backend_ceph: "yes"
cinder_backup_driver: "ceph"
nova_backend_ceph: "yes"
enable_mariabackup: "yes"
enable_neutron_agent_ha: "yes"
glance_enable_rolling_upgrade: "yes"
```
