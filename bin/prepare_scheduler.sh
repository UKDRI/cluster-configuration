#!/usr/bin/bash

sudo dnf install -y ansible-core

ansible-playbook cluster-configuration.yml
