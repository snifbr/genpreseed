# genpreseed

This project aims to automate the process of making preseed files for automating the installation of Debian based operating systems, including Ubuntu. It does this by analyzing the parameters selected during the installation of an existing system. The resulting preseed file can be used to fully automate both server and desktop Debian/Ubuntu installers with no user interaction necessary.

## Introduction
GenPreseed generates preseed files for fully automating Debian/Ubuntu
installations. It does this by analyzing the install-time options selected
during the installation of an existing system.

When some parameters cannot be detected, some sane defaults are used. The goal
of the software is to try and generate a useable preseed file on every run.

## Usage
Run the script in bash, as root or with sudo:

```bash
# bash genpreseed.sh
$ sudo bash genpreseed.sh
```

A dot-slash (./) also works as long as bash is at /bin/bash:

```bash
$ sudo ./genpreseed.sh
```

I would have rather not required root, but getting parameters from debconf requires it.

Without any arguments the script will use the template included with the software. You can specify a template file to use by specifying it as an argument to the script:

```bash
$ sudo ./genpreseed.sh /path/to/my-own-template.txt
```

## Output
The script will print informational messages and warnings to stdout, as well as the output preseed file. The generated preseed file is written to /tmp/preseed/seed.txt

Some basic instructions, as well as parameters to use when booting from an installation disk, are printed as well.

Read the messages carefully! If there are any manual steps you may need to perform to make the preseed file usable, they are explained there.

## Use Caution
By default the generated preseed file instructs the installer to use unpartitioned free space. If there is no free space, or the disk doesn't have a valid partition table, the installer will freeze.

See the output messages, or the generated preseed file, for instructions on specifying a disk or forcing the installer to overwrite any data on the specified disk.

Be careful when testing preseed installations. I would recommend always testing in a virtual environment or in a lab setup. Don't boot your important workstation into an installation CD and not expect all your data to be lost.

## Installing Debian/Ubuntu
There are multiple ways to use a preseed file when installing Debian or Ubuntu. The instructions printed by this script, specifying the use of an HTTP server, are one such method. Some methods may be easier in your use-case, others require re-mastering the installer CD.

Below are links to distribution specific instructions on preseeding:
Ubuntu: http://help.ubuntu.com/12.04/installation-guide/amd64/appendix-preseed.html
Debian: http://wiki.debian.org/DebianInstaller/Preseed
