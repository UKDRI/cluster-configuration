#!/usr/bin/bash

sudo dnf install -y  --setopt=install_weak_deps=False ansible-core

ansible-playbook cluster.yml
