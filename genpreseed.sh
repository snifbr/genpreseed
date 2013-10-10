#!/bin/bash

# (c) Copyright 2013 by Linmin Corp. (linmin.com)
# Written by Brian Peterson (briankpeterson@gmail.com) for Linmin Corp.
#
# This file is part of GenPreseed.
# http://genpreseed.sourceforge.net
#
# GenPreseed is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GenPreseed is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GenPreseed.  If not, see <http://www.gnu.org/licenses/>.

VER="v0.9.0_2013-10-09"
SCRIPTNAME=$(basename $0)
DIRNAME=$(dirname $0)
VERLINE="# ${VER} ${SCRIPTNAME} $(date)"
cat << EOM
${VERLINE}

EOM

unset EXIT
if ! test[array]=true
then
    echo "\
ERROR: This script requires a shell that supports arrays, perhaps bash?
       You can run the script \"${DIRNAME}/${SCRIPTNAME}\" or \"bash ${DIRNAME}/${SCRIPTNAME}\""
    EXIT=1
fi       

if [ $(whoami) != "root" ]
then
    echo "ERROR: This script must be run as root or with sudo."
    EXIT=1
fi


if [ $# -gt 1 ]
then
    echo "ERROR: This script can only accept one argument, the path to a preseed template file."
    EXIT=1
fi

if [ $1 ]
then
    if [ ! -e $1 ]
    then
        echo "ERROR: The file ${1} does not exist."
        EXIT=1
    else
        TEMPLATE=$1
    fi
else
    TEMPLATE="${DIRNAME}/template.seed"
    if [ ! -e ${TEMPLATE} ]
    then
        echo "ERROR: The default template, ${TEMPLATE}, is missing. Please re-download the software."
        EXIT=1
    fi
fi

if [ ${EXIT} ]
then
    cat << EOM

GenPreseed generates preseed files for fully automating Debian/Ubuntu
installations. It does this by analyzing the install-time options selected
during the installation of an existing system.

When some parameters cannot be detected, some sane defaults are used. The goal
of the software is to try and generate a useable preseed file on every run.

This script accepts one optional argument: the path to a template file. If no
template is provided the default template provided with the software is used.

The default template is designed to be sufficient for most users!

See file: ${DIRNAME}/example-template.seed.txt for more detailed information about
preseed parameters.

Project homepage:
http://genpreseed.sourceforge.net/

EOM
    exit 1
fi

# Make a directory where we are running to store outputs.
DIR="/tmp/preseed"
if [ -d ${DIR} ]
then
    cat << EOM
WARNING: The directory "${DIR}" exists. Do you want to overwrite the existing directory?
Type YES or NO
EOM

while read DELETE
do
    if [ "${DELETE}" = "YES" ]
    then
        cat << EOM
Deleting ${DIR}

EOM
        rm -rf ${DIR}
        break
    elif [ "${DELETE}" = "NO" ]
    then
        cat << EOM
Not deleting ${DIR}.
Exiting.
EOM
        exit 1
    fi
    echo "Type YES or NO"
done
fi
mkdir ${DIR}

## Define some some files for outputs.
# The final preseed file.
SEED="${DIR}/seed.txt"
# Store messages and warnings.
MESSAGES="${DIR}/messages.txt"
# Store the output of "debconf-get-selections --installer".
DEBCONFI="${DIR}/debconf-installer.txt"
# Store the list of installed task selections.
TASKSEL="${DIR}/task-selections.txt"

## SETTINGS
## These variables do not get changed by the script later.
# Hostname must be set at the boot prompt to be preseeded.
export HOSTNAME="baremetal"
##users
# Whether root-login is enabled is dependent on donor system, see below.
export ROOTPASSWORD="password"
export USERFULLNAME="LBMP User"
export USERNAME="user"
export USERPASSWORD="password"
##networking
# Enables networking during the install.
export NETENABLE="true"
# Indicate which interface to use or "auto".
export NETINTERFACE="auto"
# Choose a DHCP timeout in seconds.
export DHCPTIMEOUT="60"
# Use ntp to set the hardware clock during install.
export NTP="false"
# Use a network mirror to download updates during install.
export NETMIRROR="false"
##software
# Participate in the Debian package survey, "popularity contest."
export SURVEY="false"
# Install updates during installation,"none", "safe-upgrade", or "full-upgrade"
export UPDATES="none"
# If the following variable is set, the script will add lines to the preseed
# filie to install the packages. Seperate package names with COMMA SPACE.
# Note: Do not include openssh-server. See the SSHD variable below.
# ex. export PACKAGES="vim, apache2"
export PACKAGES=""

## VARIABLES
## The script changes these variables according to the donor system.
## These are defaults that will be used if the setting cannot be determined.
# localization
export LOCALE=${LANG}
export KEYMAP="us"
export TIMEZONE=$(cat /etc/timezone)
export UTC="true"
#users
export ROOTLOGIN="false"
##partitioning
# Set installation disk to use if not detected automatically.

# Safer option
# The "biggest_free" method is used in the preseed by default
#* with the forced method populated, but commented out.
# Set a disk to use for the "biggest_free" method.
# Should be in the form of ex. "/var/lib/partman/devices/=dev=sda"
export DISK_FREE=""

# Dangerous option - forces data destruction
# Set a disk to use if not detected automatically.
# Should be in the form of ex. "/dev/sda"
export DISK_FORCE=""
# Choose partitioning method "regular" or "lvm".
export METHOD="lvm"

# Choose auto partitioning recipe "atomic", "home", or "multi".
export RECIPE="atomic"

# Set SSHD to true if you want openssh-server installed regardless.
SSHD=""
# The task selection to be installed will be determined from the donor.
export TASK=""

# Read the debconf databases out to a file.
if ! ./${DIRNAME}/debconf-get-selections --installer > ${DEBCONFI}
then
    if grep ubiquity /var/log/installer/version
    then
        cat << EOM | tee -a ${MESSAGES}
# WARNING: It appears that the live CD, "Ubuiquity", installer was used to
#          install this operating system. This script cannot detect the disk
#          and partitioning method used at install time.
#          You may need to specify a disk manually.
#          CHECK for additional warnings with further instructions.
#
EOM
    else
        cat << EOM | tee -a ${MESSAGES}
# WARNING: No debconf database found or debconf-get-selections failed to run!
#          This script cannot detect the disk and partitioning method used at
#          install time.
#          You may need to specify a disk manually.
#          CHECK for additional warnings with further instructions.
#          You should only use a generated preseed after careful review,
#          required options may be missing.
#
EOM
   fi
fi

if ! ./${DIRNAME}/debconf-get-selections >> ${DEBCONFI}
then
    cat << EOM | tee -a ${MESSAGES}
# WARNING: No debconf database found or debconf-get-selections failed to run!
#          CHECK for additional warnings with further instructions.
#          You should only use a generated preseed after careful review,
#          required options may be missing.
#
EOM
fi

if [ $? -ne 0 ]
then
    echo "ERROR: debconf-get-selections failed to run."
    exit 1
fi

# Read the currently installed task selections out to a file..
tasksel --list-tasks | grep ^i > ${TASKSEL}
if [ $? -ne 0 ]
then
    echo "ERROR: tasksel failed to run."
    exit 1
fi

## Start out by adding a nice message to the messages file.
cat << EOM > ${MESSAGES}
################### Messages ####################
# Warning and messages from the preseed script. #
#################################################

EOM

## DONOR
## Get some information about the donor we're running on.
# Process the release file.
if [ -e /etc/os-release ]
then
    . /etc/os-release
    if [ "${ID}" == "debian" ] || [ "${ID}" == "ubuntu" ]
    then
        cat << EOM | tee -a ${MESSAGES}
# This preseed is being generated for ${PRETTY_NAME}.
# Compatibility with other other distributions is not guaranteed.
#
EOM
    else
        cat << EOM | tee -a ${MESSAGES}
# WARNING: This computer does not appear to be running Debian or Ubuntu.
#          This script may behave erratically or fail unexpectedly.
#          You should only use a generated preseed after careful review.
#          ${PRETTY_NAME} ${NAME} ${VERSION}
#
EOM
    fi
else
    cat << EOM | tee -a ${MESSAGES}
# WARNING: No release file found.
#          This script may behave erratically or fail unexpectedly.
#          You should only use a generated preseed after careful review.
#
EOM
fi

## Determine the task to be installed
if [ "${ID}" == "debian" ]
then
    if egrep "desktop|laptop" ${TASKSEL} &>/dev/null
    then
        TASK="desktop"
        cat << EOM | tee -a ${MESSAGES}
# Debian desktop install detected.
# The Debian desktop task will be installed.
#
EOM
    else
        TASK="standard"
        cat << EOM | tee -a ${MESSAGES}
# Debian standard install detected.
# A standard Debian server will be installed.
#
EOM
    fi
    cat << EOM | tee -a ${MESSAGES}
# You should use the Debian install DVD.
#
EOM
elif [ "${ID}" == "ubuntu" ]
then
    if grep "desktop" ${TASKSEL} &>/dev/null
    then
        TASK="ubuntu-desktop"
        cat << EOM | tee -a ${MESSAGES}
# Ubuntu desktop install detected.
# A standard Ubuntu desktop will be installed.
#
# You should use an Ubuntu desktop install CD.
#
EOM
    else
        TASK="server"
        cat << EOM | tee -a ${MESSAGES}
# Ubuntu server install detected.
# A standard Ubuntu server will be installed.
#
# You should use an Ubuntu server install CD.
#
EOM
    fi
else
    cat << EOM | tee -a ${MESSAGES}
# WARNING: No standard Ubuntu or Debian install was detected.
#          You should only use a generated preseed after careful review.
#          The default options (if any) from the install medium you choose will be used.
#
EOM
fi


# Determine if openssh-server is installed.
if dpkg-query -s openssh-server &>/dev/null
then
    PACKAGES="openssh-server, ${PACKAGES}"
fi

# The debconf database output is in no particular order.
# Store debconf searchable definition and the variable to be set in arrays.
# Index 0 stores the number of items to iterate over.
VARNAME[1]="LOCALE"
DEBCONF[1]="debian-installer/locale"
VARNAME[2]="KEYMAP"
DEBCONF[2]="keyboard-configuration/xkb-keymap"
VARNAME[3]="TIMEZONE"
DEBCONF[3]="time/zone"
VARNAME[4]="UTC"
DEBCONF[4]="clock-setup/utc"
VARNAME[5]="ROOTLOGIN"
DEBCONF[5]="passwd/root-login"
VARNAME[6]="DISK_FORCE"
DEBCONF[6]="partman-auto/disk"
VARNAME[7]="DISK_FREE"
DEBCONF[7]="partman-auto/select_disk"
VARNAME[8]="METHOD"
DEBCONF[8]="partman-auto/method"
VARNAME[9]="RECIPE_"
DEBCONF[9]="partman-auto/choose_recipe"
# Always make sure LASTINDX equals the last index number.
LASTINDX=9

# Iterate over the arrays above.
# The debconf definition in DEBCONF[] is grep'd for in the debconf installer file.
# If a value is found, the variable stored in VARNAME[] is set to that value.
i=1
stop=${LASTINDX}
while [ ${i} -le ${stop} ]
do
    VAL=$(grep -m1 ${DEBCONF[${i}]} ${DEBCONFI} | awk '{print $4}')
    if [ ! -z ${VAL} ]
    then
        eval ${VARNAME[${i}]}=${VAL}
    fi
    i=$[${i}+1]
done

# Check if the DISK_ variables are blank and populate the other.
# If partman-auto/select_disk, aka DISK_2 is populated, it needs to be parsed
# from ex. "/var/lib/partman/devices/=dev=sda" to "/dev/sda"
if [ -z ${DISK_FORCE} ] && [ ! -z ${DISK_FREE} ]
then
    DISK_FORCE=$(basename ${DISK_FREE} | sed s/\=/\\//g)
fi
if [ -z ${DISK_FREE} ] && [ ! -z ${DISK_FORCE} ]
then
    DISK_FREE="/var/lib/partman/devices/$(${DISK_FORCE} | sed s/\\//\=/g)"
fi

if [ -z ${DISK_FORCE} ] && [ -z ${DISK_FREE} ]
then
    cat << EOM | tee -a ${MESSAGES}
# WARNING: No installation hard disk automatically detected!
#          The installer will fail without a target installation hard disk!
#          You can fix this manually by editing the following lines in ${SEED},
#          To use free space on a disk (default), specify a disk to use
#          e.g. "/var/lib/partman/devices/=dev=sda":
#           d-i partman-auto/init_automatically_partition select biggest_free
#           d-i partman-auto/select_disk select /var/lib/partman/devices/=dev=sda
#          OR to forcefully overwrite a disk, comment out the above two lines
#          and uncomment the following two lines specifying a disk and method.
#           #d-i partman-auto/disk string /dev/sda
#           #d-i partman-auto/method string ${METHOD}
#
EOM
else
    cat << EOM | tee -a ${MESSAGES}
# NOTE: The preseed has specified using ${DISK_FORCE}.
#       By default, the safer, biggest_free method has been chosen.
#       To work, the disk must have enough available unpartitioned space AND
#       a valid partition table, even if it is empty.
#
#       To forcefully overwrite ${DISK_FORCE}, comment out the following lines
#       with #:
#        d-i partman-auto/init_automatically_partition select biggest_free
#        d-i partman-auto/select_disk select ${DISK_FREE}
#       AND uncomment the following lines by deleting the preceding #:
#        #d-i partman-auto/disk string ${DISK_FORCE}
#        #d-i partman-auto/method string ${METHOD}
#
EOM
fi

# Grep for the correct recipe to use otherwise don't change what was specified above.
case ${RECIPE_} in
    *"atomic"*) RECIPE="atomic" ;;
    *"home"*) RECIPE="home" ;;
    *"multi"*) RECIPE="multi" ;;
esac

# Read the preseed template and write the preseed file with variables replaced.
while read line
do
    echo ${line} | envsubst >> ${SEED}.tmp
done < ${TEMPLATE}

debconf-set-selections --checkonly ${SEED}.tmp 2>&1 | tee -a ${MESSAGES}; STATUS=${PIPESTATUS[0]}
if [ ${STATUS} -ne 0 ]
then
    cat << EOM | tee -a ${MESSAGES}
# WARNING: debconf-set-selections indicated errors in the generated preseed file!
#          You should only use the generated preseed after careful review.
#
EOM
fi

# Provide the commands to append at the boot prompt:
if [ "${TASK}" == 'ubuntu-desktop' ]
then
    export PROMPT="\
boot=casper automatic-ubiquity noprompt \
locale=${LOCALE} keyboard-configuration/layoutcode=${KEYMAP} \
auto url=http://<serverIP>/seed.txt"
else
    export PROMPT="\
priority=critical locale=${LOCALE} keymap=${KEYMAP} hostname=${HOSTNAME} \
auto url=http://<serverIP>/seed.txt"
fi

cat << EOM | tee -a ${MESSAGES}
# Put the preseed file on a web server and at the installer boot prompt;
# Delete the "file=..." parameter if present (scroll left),
# Leave the initrd parameter in place and append with the following:
#
# ${PROMPT}
#
EOM

cat ${MESSAGES} $(echo ${SEED}.tmp) > ${SEED}

cat << EOM

The completed preseed file has been written to ${SEED}.

EOM
