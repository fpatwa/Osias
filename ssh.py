"""Provides a class to function as a ssh client to interact with a remote IP via ssh
"""

import time
import utils


class SshClient:
    """Function as a ssh client to interact with a remote IP"""

    __SSH_OPTIONS_TEMPLATE = (
        "-o StrictHostKeyChecking=no "
        + "-o UserKnownHostsFile=/dev/null "
        + "-o ConnectTimeout=10 "
        + "-o BatchMode=yes "
    )

    def __init__(self, username, ip_address, ssh_key=None):
        """Initialize ssh credentials"""
        self.__username = username
        self.__ip_address = ip_address
        self.__ssh_key = ssh_key

    def ssh(self, command, option=None, test=True):
        """Connect to remote end using ssh"""
        if self.__ssh_key:
            keyls = f"-i {self.__ssh_key}"
        else:
            keyls = ""

        if option:
            extra_option = f"{option}"
        else:
            extra_option = ""

        ssh_cmd = ("ssh "
                  + f"{keyls} "
                  + f"{self.__SSH_OPTIONS_TEMPLATE} "
                  + f"{extra_option} "
                  + f"{self.__username}@"
                  + f"{self.__ip_address} "
                  + f"{command}"
        )

        return utils.run_cmd(ssh_cmd, test)

    def check_access(self):
        """Check access to the remote end"""
        for i in range(30):
            out = self.ssh("uname -a", test=False)
            if out == 0:
                print("Successfully connected to {}".format(self.__ip_address))
                return True
            else:
                print(
                    "Failed to connect to {}, Retry in 20 seconds".format(
                        self.__ip_address
                    )
                )
                time.sleep(20)
        return False

    def scp_to(self, file_path_local, file_path_remote=""):
        """SCP a file from the local end to remote path"""
        if self.__ssh_key is None:
            keyls = []
        else:
            keyls = ["-i", self.__ssh_key]

        call_list = (
            ["scp", "-r"]
            + keyls
            + [
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "UserKnownHostsFile=/dev/null",
                "-o",
                "ConnectTimeout=10",
                "-o",
                "BatchMode=yes",
                file_path_local,
                self.__username + "@" + self.__ip_address + ":" + file_path_remote,
            ]
        )

        return utils.run_cmd(' '.join(call_list))

    def scp_from(self, file_path_remote, file_path_local="."):
        """SCP a file from the remote end to local path"""
        if self.__ssh_key is None:
            keyls = []
        else:
            keyls = ["-i", self.__ssh_key]

        call_list = (
            ["scp", "-r"]
            + keyls
            + [
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "UserKnownHostsFile=/dev/null",
                "-o",
                "ConnectTimeout=10",
                "-o",
                "BatchMode=yes",
                self.__username + "@" + self.__ip_address + ":" + file_path_remote,
                file_path_local,
            ]
        )

        return utils.run_cmd(' '.join(call_list))
