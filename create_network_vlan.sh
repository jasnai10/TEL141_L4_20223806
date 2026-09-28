#!/bin/bash

set -euo pipefail

BRIDGE="br-int"


# Validacion de parametros

if [ "$#" -lt 3 ]; then
    echo "[ERROR] Parametros insuficientes."
    echo "Uso: $0 <VLAN_ID> <CIDR> <dhcp:on|off> [rango_ini] [rango_fin]"
    exit 1
fi

VLAN_ID="$1"          
CIDR="$2"             
DHCP="$3"             
RANGE_START="${4:-}" 
RANGE_END="${5:-}"   

# Calculo de direcciones a partir del CIDR

NETWORK="${CIDR%/*}"          
PREFIX="${CIDR#*/}"           
BASE="${NETWORK%.*}"         
GATEWAY_IP="${BASE}.1"       
DHCP_IP="${BASE}.2"         

GW_PORT="gw_vlan${VLAN_ID}"    
NS="ns-dhcp-vlan${VLAN_ID}"         
DHCP_PORT="dhcp_v${VLAN_ID}"         


# 1. Crear la interfaz interna del gateway en el OVS

echo "[INFO] Creando puerto interno '$GW_PORT' (VLAN $VLAN_ID) como gateway..."
sudo ovs-vsctl --may-exist add-port "$BRIDGE" "$GW_PORT" tag="$VLAN_ID" \
    -- set interface "$GW_PORT" type=internal


sudo ip addr add "${GATEWAY_IP}/${PREFIX}" dev "$GW_PORT" 2>/dev/null || true
sudo ip link set dev "$GW_PORT" up
echo "[OK] Gateway de la VLAN $VLAN_ID configurado en ${GATEWAY_IP}/${PREFIX}."


# 2. Si DHCP esta habilitado, montar el servicio en un namespace

if [ "$DHCP" == "on" ]; then

    if [ -z "$RANGE_START" ] || [ -z "$RANGE_END" ]; then
        echo "[ERROR] DHCP habilitado pero no se indico el rango de direcciones."
        echo "Uso: $0 <VLAN_ID> <CIDR> on <rango_ini> <rango_fin>"
        exit 1
    fi

    echo "[INFO] Configurando servicio DHCP para la VLAN $VLAN_ID..."

    # 2a. Puerto interno del OVS para el DHCP, asociado a la VLAN.
    sudo ovs-vsctl --may-exist add-port "$BRIDGE" "$DHCP_PORT" tag="$VLAN_ID" \
        -- set interface "$DHCP_PORT" type=internal

    # 2b. Crear el network namespace (idempotente).
    sudo ip netns add "$NS" 2>/dev/null || true

    # 2c. Mover el puerto DHCP dentro del namespace.
    sudo ip link set "$DHCP_PORT" netns "$NS"

    # 2d. Configurar la IP del DHCP (segunda direccion) dentro del namespace
    #     y levantar interfaces.
    sudo ip netns exec "$NS" ip addr add "${DHCP_IP}/${PREFIX}" dev "$DHCP_PORT"
    sudo ip netns exec "$NS" ip link set dev "$DHCP_PORT" up
    sudo ip netns exec "$NS" ip link set dev lo up

    # 2e. Lanzar dnsmasq dentro del namespace.
    echo "[INFO] Iniciando dnsmasq (rango ${RANGE_START}-${RANGE_END}, gw ${GATEWAY_IP})..."
    sudo ip netns exec "$NS" dnsmasq \
        --interface="$DHCP_PORT" \
        --bind-interfaces \
        --dhcp-range="${RANGE_START},${RANGE_END},255.255.255.0,12h" \
        --dhcp-option=3,"${GATEWAY_IP}"

    echo "[OK] Servicio DHCP activo en ${DHCP_IP} para la VLAN $VLAN_ID."
else
    echo "[INFO] DHCP deshabilitado para la VLAN $VLAN_ID."
fi

echo "[OK] Red VLAN $VLAN_ID creada correctamente."