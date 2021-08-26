#!/usr/bin/env bash

SERVICES="edge-core edge-proxy kubelet maestro pelion-relay-term devicedb wait-for-pelion-identity"

function installed() {
	local services=""
	for s in ${SERVICES}; do
		if dpkg -l $s &>/dev/null; then
			services="${services} $s"
		fi
	done
	echo ${services}
}

ACTION=$1
case ${ACTION} in
	installed)
		i=$(installed)
		echo "    installed: ${i}"
		echo "not installed: $(echo ${i} ${SERVICES} | uniq -u)"
		;;

	status)
		for s in $(installed); do
			systemctl status $s --lines 0 --no-pager
		done
		;;

	stop|start|restart|disable|enable)
		for s in $(installed); do
			systemctl $ACTION $s
		done
		;;

	*)
		echo "${ACTION}: unknown command"
		exit 1
		;;
esac
