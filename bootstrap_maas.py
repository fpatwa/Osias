#!/usr/bin/python3

import argparse
import time
from maas_base import maas_base

from utils import run_cmd


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "operation",
        type=str,
        choices=[
            "deploy_maas",
            "deploy_virsh",
            "deploy_networking",
            "full_deployment",
            "remove_maas",
            "deploy_virsh_vm",
        ],
        help="Operation to perform",
    )

    args = parser.parse_args()
    print(args)
    return args


def check_import_status():
    result = run_cmd("sudo maas admin boot-resources is-importing")
    while str(result, "utf-8") == "true":
        print("Images are still importing...")
        time.sleep(2)
        result = run_cmd("sudo maas admin boot-resources is-importing")
    if str(result, "utf-8") == "false":
        print("Import is complete")
        return


def deploy_maas():
    run_cmd("sudo apt update")
    run_cmd("sudo apt install -y snap snapd")
    run_cmd("sudo snap install --channel=2.9/stable maas")
    run_cmd("sudo snap install maas-test-db")
    run_cmd(
        "yes '' | sudo maas init region+rack --database-uri maas-test-db:/// --force"
    )
    run_cmd("sudo maas config --show")
    run_cmd(
        "sudo maas createadmin --username=admin --email=admin@example.com --password password --ssh-import noimport"
    )
    run_cmd("sudo maas apikey --username=admin > /tmp/API_KEY_FILE")
    time.sleep(2)
    maas_url = (
        str(run_cmd("sudo maas config --show | grep maas_url"), "utf-8")
        .split("=")[1]
        .rstrip()
    )
    run_cmd(f"sudo maas login admin {maas_url}/api/2.0 - < /tmp/API_KEY_FILE")
    run_cmd("ssh-keygen -b 2048 -t rsa -f /tmp/sshkey -q -N ''")
    run_cmd('sudo maas admin sshkeys create "key=$(cat /tmp/sshkey.pub)"')
    run_cmd("sudo maas admin maas set-config name=upstream_dns value=10.250.53.202")
    run_cmd(
        "sudo maas admin boot-source-selections create 1 os='ubuntu' release='bionic' arches='amd64' subarches='*' labels='*'"
    )
    run_cmd("sudo maas admin boot-resources import")
    check_import_status()


def deploy_virsh():
    run_cmd(
        "sudo apt-get -y install qemu-kvm libvirt-bin bridge-utils virt-manager virtinst libvirt-clients libvirt-daemon-system qemu-system-x86 qemu-utils"
    )
    run_cmd("sudo virsh net-destroy default")
    run_cmd("sudo virsh net-dumpxml default > virsh.default.net.xml")
    run_cmd("sed -i '/<dhcp>/,/<\/dhcp>/d' virsh.default.net.xml")
    run_cmd("sudo virsh net-create virsh.default.net.xml")


def deploy_virsh_vm():
    run_cmd(
        "sudo virt-install --name=testVM --description 'Test MaaS VM' "
        "--os-type=Linux --os-variant=ubuntu18.04 --ram=2048 --vcpus=2 "
        "--disk path=/var/lib/libvirt/images/ubuntu-testVM.qcow2,size=20,bus=virtio "
        "--noautoconsole --graphics=none --hvm --boot network "
        "--pxe --network network=default,model=virtio"
    )
    uuid = str(run_cmd("sudo virsh domuuid testVM"), "utf-8").rstrip()
    mac_addr = str(
        run_cmd(
            "sudo virsh dumpxml testVM | grep 'mac address' | awk -F\\' '{print $2}'"
        ),
        "utf-8",
    ).rstrip()
    run_cmd(
        "sudo maas admin machines create architecture=amd64 "
        f"mac_addresses={mac_addr} power_type=virsh "
        "power_parameters_power_address=qemu+ssh://ubuntu@127.0.0.1/system "
        f"power_parameters_power_id={uuid}"
    ) # power_parameters_power_pass="


# class maas_virtual(maas_base):
def configure_maas_networking():
    run_cmd(
        "sudo maas admin ipranges create type=dynamic start_ip=192.168.122.100 end_ip=192.168.122.120"
    )
    primary_rack = maas_base._run_maas_command(
        self="", command="rack-controllers read"
    )[0]["system_id"]
    print(f"PRIMARY RACK: {primary_rack}")
    vlan_info = maas_base._run_maas_command(self="", command="subnets read")
    for vlan in vlan_info:
        if "192.168.122" in str(vlan):
            if "192.168.122" in str(vlan):
                # primary_rack = vlan["vlan"]["primary_rack"]
                vid = vlan["vlan"]["vid"]
                fabric_id = vlan["vlan"]["fabric_id"]
                maas_base._run_maas_command(
                    self="",
                    command=f"vlan update {fabric_id} {vid} dhcp_on=True primary_rack={primary_rack}"
                )
    maas_base._run_maas_command("subnet update 192.168.122.0/24 gateway_ip=192.168.122.1")


def full_deployment():
    deploy_maas()
    deploy_virsh()
    maas_virtual.configure_maas_networking()
    deploy_virsh_vm()


def remove_maas():
    run_cmd("sudo snap remove maas-test-db")
    run_cmd("sudo snap remove maas")
    run_cmd("sudo apt -y purge snapd")
    run_cmd("rm /tmp/API_KEY_FILE /tmp/sshkey*")
    run_cmd("sudo reboot now")


def main():
    args = parse_args()
    if args.operation == "deploy_maas":
        deploy_maas()
    elif args.operation == "deploy_virsh":
        deploy_virsh()
    elif args.operation == "deploy_networking":
        configure_maas_networking()
    elif args.operation == "full_deployment":
        full_deployment()
    elif args.operation == "deploy_virsh_vm":
        deploy_virsh_vm()
    elif args.operation == "remove_maas":
        remove_maas()


if __name__ == "__main__":
    main()
