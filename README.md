# Cluster configuration


Ansible playbook to install softwares, configure Nextflow and nf-core, and configure
Slurm accounting on an Azure CycleCloud pipeline using AlmaLinux


## Requirements

Ansible needs to be installed with pip. Ansible is provided by AlmaLinux but the
dnf module used to install packages needs the system Python (3.6) and Ansible is
packaged with Python 3.12.

There is a script in `bin` which will install `ansible-core` and `ansible-lint`
to be able to check the YAML files when modifying the roles.


## Configuring the cluster

```bash
git clone https://github.com/UKDRI/cluster-configuration
cd cluster-configuration
./bin/prepare_scheduler.sh
```

The script will install the dependencies and run ansible-playbook.

You can also just run the playbook

```bash
ansible-playbook cluster.yml
```


## Steps of the configuration


### Getting the cluster name

It will retrieve the cluster name using the Slurm command `scontrol show config`
as it will be needed to configure SlurmDBD later. It also generate the scheduler
hostname to compare with `HOSTNAME` as we only want to install the software on the
scheduler and not on the compute nodes.


### Set the default Java

Nextflow needs Java 17 at minimum. This steps install Java 17 and sets it to be the
default Java


### Install Nextflow

We are using Nextflow version 24.10.0 which is installed in `/usr/local/bin`.


### Install everyday software

Currently we install the following list of software which can be expanded:

- vim
- screen


### Add UK DRI users to the docker group

If you have access to the HPC, you will have access to Docker


### Configure Slurm Accounting

#### Setting SlurmDBD

A random password is created and used to generate the configuration files


### Configuring MariaDB

It install MariaDB and creates a password for root only accessible to the creator
of the database. It also create a "slurm" user with password. The slurm user is
able to create databases.


### Restart the daemons

It will restart `slurmdbd` and `slurmctl` and the system will be ready to use!!