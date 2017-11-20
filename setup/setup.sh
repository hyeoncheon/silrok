#!/bin/bash
# 
# vim:set ts=2 sw=2:

script=`readlink -f $PWD/$_`
silrok_home=${script%/setup/setup.sh}

if [ ! -d "$silrok_home/setup" ]; then
	echo "cannot determined silrok home. what's going on? maybe a bug! abort!"
	exit
fi

if [ ! -f "$silrok_home/defaults.conf" ]; then
	echo "cannot found default configuration file (defaults.conf). abort!"
	exit
fi

# default values from distribution
. $silrok_home/defaults.conf

# overrided values from user's environment
[ -f $silrok_home/config.conf ] && . $silrok_home/config.conf

export cluster_name
export admin_network
export kibana_port
export port_softlayer_ticket

if [ "$1" = "debug" ]; then
	run=echo
else
	run=
fi

# install and basic setup
for s in $silrok_home/setup/0*; do
	$run $s
done

# setup addons
for s in $addons; do
	$run $silrok_home/setup/addons/$s.sh
done
