# docker run -ti -v ~/deploy-openstack-master:/test python:3.7-buster bash
# pip3 install toml timeout_decorator

export MAAS_API_KEY="<INSERT KEY HERE>"
export MAAS_URL="http://<YOUR MAAS IP HERE>:5240/MAAS"
export DOCKER_REGISTRY_PASSWORD="<LOCAL_DOCKER_PASSWORD HERE>"

read -r -d '' MULTINODE << EOF
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
[variables]
    [variables.0]
    RAID = false
    DOCKER_REGISTRY = "172.16.0.14"
    DOCKER_REGISTRY_USERNAME = "kolla"
EOF
