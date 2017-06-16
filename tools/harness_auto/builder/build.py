#!/usr/bin/python

import sys

import docker

def main():

    client = docker.from_env()
    client.containers.run("ubuntu", "echo hello world")


if __name__ == '__main__':
    main()
