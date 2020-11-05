"""Provides a class to function as a ssh client to interact with a remote IP via ssh
"""

import subprocess
import time


class SshClient:
    """Function as a ssh client to interact with a remote IP"""

    def __init__(self, username, ip_address, sshkey=None):
        """Initialize ssh credentials"""
        self.rem_username = username
        self.ip = ip_address
        self.sshkey = sshkey

    def ssh(self, command, test=True, option=None, output=False, silent=False):
        """Connect to remote end using ssh"""
        if self.sshkey is None:
            keyls = []
        else:
            keyls = ["-i", self.sshkey]

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

        call_list.extend([self.rem_username + "@" + self.ip, command])

        print("SshClient: " + " ".join(call_list))

        stdout = ""
        ret = -1
        if output or silent:
            try:
                stdout = subprocess.check_output(
                    call_list, stderr=subprocess.STDOUT
                )
                ret = 0
            except subprocess.CalledProcessError as e:
                ret = e.returncode
                print(e)
                print(stdout)
        else:
            ret = subprocess.call(call_list)

        if ret != 0:
            print(stdout)

        # By default, it is not ok to fail
        if test:
            assert ret == 0

        if output:
            return stdout
        else:
            return ret

    def check_access(self):
        """Check access to the remote end"""
        for i in range(30):
            out = self.ssh("uname -a", test=False)
            if out == 0:
                print("Successfully connected to {}".format(self.ip))
                return True
            else:
                print(
                    "Failed to connect to {}, Retry in 20 seconds".format(
                        self.ip
                    )
                )
                time.sleep(20)
        return False

    def scp_to(self, file_path_local, file_path_remote="", test=True):
        """SCP a file from the local end to remote path"""
        if self.sshkey is None:
            keyls = []
        else:
            keyls = ["-i", self.sshkey]

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
                self.rem_username + "@" + self.ip + ":" + file_path_remote,
            ]
        )

        print("SshClient: " + " ".join(call_list))

        ret = subprocess.call(call_list)

        # By default, it is not ok to fail
        if test:
            assert ret == 0

        return ret

    def scp_from(self, file_path_remote, file_path_local=".", test=True):
        """SCP a file from the remote end to local path"""
        if self.sshkey is None:
            keyls = []
        else:
            keyls = ["-i", self.sshkey]

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
                self.rem_username + "@" + self.ip + ":" + file_path_remote,
                file_path_local,
            ]
        )

        print("SshClient: " + " ".join(call_list))

        ret = subprocess.call(call_list)

        # By default, it is not ok to fail
        if test:
            assert ret == 0

        return ret
