#!/bin/bash

set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "[ERROR] Parametros insuficientes."
    echo "Uso: $0 <VLAN_ID> <CIDR> [iface_salida]"
    exit 1
fi

VLAN_ID="$1"                
CIDR="$2"
OUT_IFACE="${3:-ens3}"    
GW_PORT="gw_vlan${VLAN_ID}" 

echo "[INFO] Habilitando salida a Internet para la VLAN $VLAN_ID (${CIDR})..."


# 1. NAT dinamico (MASQUERADE): enmascara la IP privada de la VLAN con la IP
#    de la interfaz externa de salida.
sudo iptables -t nat -C POSTROUTING -s "$CIDR" -o "$OUT_IFACE" -j MASQUERADE 2>/dev/null \
    || sudo iptables -t nat -A POSTROUTING -s "$CIDR" -o "$OUT_IFACE" -j MASQUERADE


# 2. Autorizar el trafico de ida (VLAN -> Internet) en la cadena FORWARD.
sudo iptables -C FORWARD -i "$GW_PORT" -o "$OUT_IFACE" -j ACCEPT 2>/dev/null \
    || sudo iptables -A FORWARD -i "$GW_PORT" -o "$OUT_IFACE" -j ACCEPT


# 3. Autorizar el trafico de retorno (conexiones establecidas/relacionadas).
sudo iptables -C FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null \
    || sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "[OK] Salida a Internet habilitada para la VLAN $VLAN_ID."