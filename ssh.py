"""Provides a class to function as a ssh client to interact with a remote IP via ssh
"""

import subprocess
import time


class SshClient:
    """Function as a ssh client to interact with a remote IP"""

    def __init__(self, username, ip_address, ssh_key=None):
        """Initialize ssh credentials"""
        self.__username = username
        self.__ip_address = ip_address
        self.__ssh_key = ssh_key

    def __run(command, test=True, silent=True):
        if not silent:
            print(f"\n[Command Issued:]\n\t{command}\n"

        stdout = None
        try:
            stdout = subprocess.check_output(command, stderr=subprocess.STDOUT, shell=True)
        except subprocess.CalledProcessError as e:
            if test:
                raise Exception(e.output.decode()) from e
            else:
                print(e.output.decode())

        if not silent:
            print(f"\n[Command Output:]\n{stdout.decode()}\n")

        return stdout

    def ssh(self, command, option=None, test=True, silent=False):
        """Connect to remote end using ssh"""
        if self.__ssh_key is None:
            keyls = []
        else:
            keyls = ["-i", self.__ssh_key]

        call_list = (
            ["ssh"]
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
            ]
        )

        if option:
            call_list.extend(["-o", option])

        call_list.extend([self.__username + "@" + self.__ip_address, command])

        if not silent:
            print("SshClient ssh: " + " ".join(call_list))

        return self.__run(call_list, test, silent)

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

        print("SshClient scp: " + " ".join(call_list))

        return self.__run(call_list, silent=False)

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

        print("SshClient scp: " + " ".join(call_list))

        return self.__run(call_list, silent=False)
