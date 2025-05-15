#!/bin/bash

# ========================================================
# Script Name   :  virtual_host.sh
# Description   :  Manager virtual host
# Author        :  Alex Fan
# Create Data   :  2025-05-13
# Version       :  1.0
# Usage         :  bash virtual_host.sh [--args]
# ========================================================

# Exit the script on error
set -e 

# Kubernetes virtual host
PWROFF_HOST=`virsh list --state-shutoff | grep -E "(kubeadm|lvs)"|awk '{print $2}'`
PWRON_HOST=`virsh list --state-running | grep -E "(kubeadm|lvs)"|awk '{print $2}'`
ATSTART_HOST=`virsh list --no-autostart | grep -E "(lvs|kubeadm)"|awk '{print $2}'`
UNATSTART_HOST=`virsh list --autostart | grep -E "(lvs|kubeadm)"|awk '{print $2}'`

function launch_virtual_hosts(){
        for host in ${PWROFF_HOST}
        do
                virsh start ${host}
                sleep 1
        done
}

function shutoff_virtual_hosts(){
        for host in ${PWRON_HOST}
        do
                virsh shutdown ${host}
                sleep 1
        done
}

function enable_autostart(){
        for host in ${ATSTART_HOST}
        do
                virsh autostart $host
                sleep 1
        done
}

function disable_autostart(){
        for host in ${UNATSTART_HOST}
        do
                virsh autostart $host --disable
                sleep 1
        done
}

function usage(){
        echo -e "\033[1m$0 [ARGS]\033[0m"
        echo -e "\033[35m\tARGS: \033[0m"
        echo -e "\033[34m\t\t--start: Start a shut down virtual machine\033[0m"
        echo -e "\033[34m\t\t--shutdown: Shut down the virtual machine that is already powered on\033[0m"
        echo -e "\033[34m\t\t--autostart: Enable virtual host to autostart\033[0m"
        echo -e "\033[34m\t\t--disable_autostart: Disable virtual host to autostart\033[0m"
}

case $1 in
        --start)
                launch_virtual_hosts
                ;;
        --shutdown)
                shutoff_virtual_hosts
                ;;
        --autostart)
                enable_autostart
                ;;
        --disable_autostart)
                disable_autostart
                ;;
        *)
                usage
                ;;
esac