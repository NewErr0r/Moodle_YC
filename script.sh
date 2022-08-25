#!/bin/bash

dnf install -y epel-release
dnf install -y python3 firewalld
systemctl enable --now firewalld