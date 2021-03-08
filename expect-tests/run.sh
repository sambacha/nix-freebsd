#!/usr/bin/env nix-shell
#!nix-shell -p expect -i bash

echo hi

set -eu

. ./config.sh

uuid=$1
region=$2
ipv4_public=$3

expect -d ./test.expect "$uuid" "$region" "$ipv4_public"

exit 0


#ipv4_private=$5
#ipv6_public=$4

target_ipv4_public=$TEST_IPV4_PUBLIC
target_ipv6_public=$TEST_IPV6_PUBLIC
#target_ipv4_private=$TEST_IPV4_PRIVATE

sshopts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

retry() {
    for i in $(seq 1 10); do
        if "$@"; then
            return 0
        fi
        sleep 3
    done

    "$@"
}

check_network() {
    while ! ping -c1 "$ipv4_public"; do
        sleep 1
    done

    retry ssh $sshopts root@"$ipv4_public" true
    retry ssh $sshopts root@"$ipv4_public" curl https://ipv4.icanhazip.com
    retry ssh $sshopts root@"$ipv4_public" curl https://ipv6.icanhazip.com

    retry ssh $sshopts root@"$ipv4_public" ping -c1 "$target_ipv4_public"
    retry ssh $sshopts -A root@"$ipv4_public" ssh $sshopts root@"$target_ipv4_public" true

    retry ssh $sshopts root@"$ipv4_public" ping -c1 "$target_ipv6_public"
    retry ssh $sshopts -A root@"$ipv4_public" ssh $sshopts root@"$target_ipv6_public" true

    #retry ssh $sshopts root@"$ipv4_public" ping -c1 "$target_ipv4_private"
    #retry ssh $sshopts -A root@"$ipv4_public" ssh $sshopts root@"$target_ipv4_private" true
}

# Install-time boot
expect -d ./journal.expect "$uuid" "$region"

# Boot to actual install
expect -d ./run-welcome.expect "$uuid" "$region"

echo "INSTALL COMPLETE AT $(date)"

check_network
#ssh $sshopts root@"$ipv4_public" hello
ssh $sshopts root@"$ipv4_public" nixos-rebuild boot
ssh $sshopts root@"$ipv4_public" reboot || true


expect -d ./run.expect "$uuid" "$region"

check_network
