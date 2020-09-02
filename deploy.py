#!/usr/bin/python3

import argparse
import os
import sys
import time
from ssh_tool import ssh_tool


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "-i",
        "--sshkey",
        type=str,
        required=False,
        help="The path to the SSH key used to access the target node")
    parser.add_argument(
        "--sudo",
        action="store_true",
        required=False,
        help="Option to elevate to sudo")
    parser.add_argument(
        "--scp",
        action="store_true",
        required=False,
        help="Option to scp script to the target node")
    parser.add_argument(
        "-c",
        "--command",
        type=str,
        required=True,
        help="The command/script that will be run on the target node")
    parser.add_argument(
        "--args",
        type=str,
        required=False,
        help="Arguments that will be passed in to the script to be run on the target node")
    parser.add_argument(
        "-n",
        "--target_node",
        type=str,
        required=True,
        help="The target node IP address that will the specified script will run on")

    args = parser.parse_args()
    print(args)

    return args


def main():
    args = parse_args()

    client = ssh_tool('ubuntu', args.target_node)

    if not client.check_access():
        print('Failed to connect to target node with IP {} using SSH'.format(
            args.target_node))
        raise Exception(
            'ERROR: Failed to connect to target node with IP {} using SSH'.format(
                args.target_node))

    cmd = args.command

    if args.args:
        cmd = ''.join((args.command, ' "', args.args, '"'))

    if args.scp:
        if not os.path.isfile(args.command):
            raise Exception(
                'ERROR: Specified script to scp {} does not exist', format(
                    args.command))
        else:
            cmd = ''.join(('source ', cmd))
            client.scp_to(args.command)

    if args.sudo:
        cmd = ''.join(('sudo -s ', cmd))

    client.ssh(cmd)


if __name__ == '__main__':
    main()
