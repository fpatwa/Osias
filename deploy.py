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
        "-s",
        "--script_name",
        type=str,
        required=True,
        help="The name of the script that will scp'ed to the target node and run")
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

    client.scp_to(args.script_name)
    client.ssh('source ' + args.script_name)


if __name__ == '__main__':
    main()
