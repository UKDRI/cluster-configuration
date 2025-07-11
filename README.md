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


### Add configuration files

It copies the set of config files and parameters files for Nextflow in the directory
specified, default is `/shared/data/nextflow`.

It will also create a configuration files which can be copied in `.nextflow`. It
will allow the use of `-profile` when running nextflow

### Install everyday software

Currently we install the following list of software which can be expanded:

- vim
- screen


### Install helper scripts

These would be written in-house to help do stuff on the HPC, installed in `/usr/local/bin`.

- addicp.sh: A script to copy data to the ADDI workbench. It creates an MD5 checksum
    file which is also copied in order to verify the files copied


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


### Fetch genome data

We are fetching the reference assembly for human and mouse and the GTF files associated
with a set of releases.

We also download the GMT files needed for g:Profiler. If the release used in the
GMT file is not present in the set of releases, it will be added.


## Implementation choices

I made the choice of having all variables in the `defaults/main.yml` of each roles.
I wanted to avoid to have to look at multiple files to find the variable.

The Nextflow configuration and params files are not using templates. I thought they
could be used from the repository directly and be modified more easily than a template.

The playbook needs to be run locally because:

- it only needs to be run on the scheduler node
- the ip adress changes every reboot so the inventory would have to change every
    reboot
- SSH access and vault would need to be configured and password to be shared