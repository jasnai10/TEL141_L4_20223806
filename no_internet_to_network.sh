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

echo "[INFO] Eliminando salida a Internet para la VLAN $VLAN_ID (${CIDR})..."

# 1. Eliminar la regla de NAT MASQUERADE (si existe).

sudo iptables -t nat -D POSTROUTING -s "$CIDR" -o "$OUT_IFACE" -j MASQUERADE 2>/dev/null \
    && echo "[OK] Regla NAT MASQUERADE eliminada." \
    || echo "[WARN] No existia la regla NAT MASQUERADE."


# 2. Eliminar la regla FORWARD de ida (VLAN -> Internet) (si existe).

sudo iptables -D FORWARD -i "$GW_PORT" -o "$OUT_IFACE" -j ACCEPT 2>/dev/null \
    && echo "[OK] Regla FORWARD de salida eliminada." \
    || echo "[WARN] No existia la regla FORWARD de salida."

echo "[OK] Salida a Internet deshabilitada para la VLAN $VLAN_ID."