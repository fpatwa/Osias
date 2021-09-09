"""
Dictionary of values containing the following:
    Number_of_VM_Servers,
    vCPU,
    RAM_in_MB,
    HDD1,
    HDD2,
    Internal_CIDR,
    Public_CIDR,
    Data_CIDR,
    VM_Deployment_CIDR,
    RAID

Number_of_VM_Servers: 3 to 7 VM's can be deployed in a test environment
HDD1 is the primary disk; HDD2-4 is used for Ceph/RAID,
Internal_CIDR is the internal CIDR from MaaS to assign an interface to VM,
Public_CIDR is the public CIDR from MaaS to assign an interface to the VM,
Data_CIDR is the private high speed CIDR from MaaS to assign an interface to the VM,
VM_Deployment_CIDR is a small /28 CIDR used for assigning a public IP to the VM,
    allocating IP's as floating IPs for OpenStack, and a VIP address for horizon
RAID: either true or absent, default is false.

example input:
{'vCPU': 8, 'RAM_in_MB': 16384, 'HDD1': 60, 'HDD2': 10, 'HDD3': 10, 'HDD4': 10, 'Internal_CIDR': '192.168.1.0/24',
'Number_of_VM_Servers': 3, 'Public_CIDR': '10.245.121.0/24', 'Data_CIDR': '10.100.0.0/16', 'DNS_IP': '10.250.53.202'}
"""

VIP_ADDRESS_SUFFIX = "250"
DOCKER_REGISTRY_IP = "10.245.0.14"
DOCKER_REGISTRY_USERNAME = "kolla"
CEPH = False

VM_Profile = {
    "Number_of_VM_Servers": 3,
    "vCPU": 8,
    "RAM_in_MB": 16384,
    "HDD1": 60,
    "HDD2": 10,
    "HDD3": 10,
    "HDD4": 10,
    "Internal_CIDR": "192.168.1.0/24",
    "Data_CIDR": "",
    "DNS_IP": "",
    "vm_deployment_cidr": "",
}

SUPPORTED_OPENSTACK_RELEASE = ["ussuri", "victoria", "wallaby"]
PYTHON_VERSION = {"ussuri": "3.8", "victoria": "3.8", "wallaby": "3.8"}
TEMPEST_VERSION = {"ussuri": "27.0.0", "victoria": "27.0.0", "wallaby": "27.0.0"}
ANSIBLE_VERSION = {"ussuri": "2.9", "victoria": "2.9", "wallaby": "2.10"}
REFSTACK_TEST_VERSION = {
    "ussuri": "2020.11",
    "victoria": "2020.11",
    "wallaby": "2020.11",
}
MAAS_VM_DISTRO = {
    "ussuri": "bionic hwe_kernel=hwe-18.04",
    "victoria": "focal hwe_kernel=hwe-20.04",
    "wallaby": "focal hwe_kernel=hwe-20.04",
}
