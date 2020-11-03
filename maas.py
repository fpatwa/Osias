#!/usr/bin/python3

import json
import timeout_decorator
import time
import utils

class servers:
    # machine_list is json blob from `maas machines read`
    def __init__(self, public_ips):
        self.public_ips = public_ips
        self.machine_list = self.findMachineIDs()

    def findMachineIDs(self):
        machine_list = utils.run_cmd('maas admin machines read', output=False)
        machine_list = json.loads(machine_list)
        deployment_list = []
        for machine in machine_list:
            check = any(item in self.public_ips for item in machine["ip_addresses"])
            if check:
                deployment_list.append(machine["system_id"])
        self.machine_list = deployment_list
        return deployment_list

    @timeout_decorator.timeout(1800, timeout_exception=StopIteration)
    def waiting(self, server_list, desired_status):
        while len(server_list) > 0:
            machine_info_list = utils.run_cmd('maas admin machines {}'.format("read"), output=False)
            machine_info_list = json.loads(machine_info_list)
            for server in server_list[:]:
                for machine in machine_info_list:
                    if server in machine["system_id"]:
                        current_status = machine["status_name"]
                        print("\n\nSERVER: {}\nCURRENT STATUS: {}\nDESIRED STATUS: {}".format(server, current_status, desired_status))
                        if current_status == desired_status:
                            print("STATE: COMPLETE.")
                            server_list.remove(server)
                            break
                        elif current_status == "Failed deployment":
                            print("STATE: Re-deploying.")
                            self.deploy([server])
                        else:
                            print("STATE: Waiting")
                    else:
                        continue 
            if len(server_list) > 0:
                print("Sleeping 60 seconds.")
                time.sleep(60)
            else:
                continue
        print("All servers have reached the desired state.")
        return

    def release(self, server_list):
        for machine in server_list[:]:
            utils.run_cmd('maas admin machine {} {}'.format("release", machine), output=False)
        self.waiting(server_list, "Ready")
        return

    def deploy(self, server_list=None):
        if server_list:
            server_list = server_list
        else:
            server_list = self.machine_list
        self.release(server_list[:])
        for machine in server_list[:]:
            utils.run_cmd('maas admin machine {} {}'.format("deploy", machine), output=False)
        self.waiting(server_list[:], "Deployed")
        return
