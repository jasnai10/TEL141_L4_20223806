#!/bin/bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "[ERROR] Debe indicar exactamente dos VLAN ID."
    echo "Uso: $0 <VLAN_ID_1> <VLAN_ID_2>"
    exit 1
fi

VLAN1="$1"
VLAN2="$2"
GW1="gw_vlan${VLAN1}"
GW2="gw_vlan${VLAN2}"

echo "[INFO] Habilitando ruteo entre la VLAN $VLAN1 y la VLAN $VLAN2..."

# Sentido 1: VLAN1 -> VLAN2
sudo iptables -C FORWARD -i "$GW1" -o "$GW2" -j ACCEPT 2>/dev/null \
    || sudo iptables -A FORWARD -i "$GW1" -o "$GW2" -j ACCEPT

# Sentido 2: VLAN2 -> VLAN1
sudo iptables -C FORWARD -i "$GW2" -o "$GW1" -j ACCEPT 2>/dev/null \
    || sudo iptables -A FORWARD -i "$GW2" -o "$GW1" -j ACCEPT

echo "[OK] Ruteo bidireccional habilitado entre la VLAN $VLAN1 y la VLAN $VLAN2."