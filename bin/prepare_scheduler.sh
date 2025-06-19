#!/usr/bin/bash

python3 -m pip install ansible-core ansible-lint

ansible-playbook cluster.yml
