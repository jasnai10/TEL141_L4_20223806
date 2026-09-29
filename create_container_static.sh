#!/bin/bash

if [ "$#" -ne 5 ]; then
    echo "[ERROR] Uso: $0 <nombre_contenedor> <bridge> <vlan_id> <ip_cidr> <gateway>"
    exit 1
fi

CONT_NAME="$1"
BRIDGE="$2"
VLAN_ID="$3"
IP_CIDR="$4"
GATEWAY="$5"

VETH_OVS="veth_ovs_${VLAN_ID}"
VETH_CONT="veth_cont_${VLAN_ID}"

# 1. Crear el contenedor sin red automatica
echo "[INFO] Creando contenedor '${CONT_NAME}' (VLAN ${VLAN_ID})..."
sudo docker run --rm --network none --name "$CONT_NAME" \
    --cap-add=NET_ADMIN -d alpine sleep infinity

# 2. Crear el par de interfaces veth
sudo ip link add "$VETH_OVS" type veth peer name "$VETH_CONT" 2>/dev/null || true

# 3. Conectar veth_ovs al bridge en la VLAN indicada
sudo ovs-vsctl --may-exist add-port "$BRIDGE" "$VETH_OVS" tag="$VLAN_ID"
sudo ip link set dev "$VETH_OVS" up

# 4. Mover veth_cont al namespace del contenedor
PID=$(sudo docker inspect -f '{{.State.Pid}}' "$CONT_NAME")
sudo ip link set "$VETH_CONT" netns "$PID"

# 5. Activar la interfaz y asignar IP ESTATICA + gateway dentro del contenedor
sudo docker exec "$CONT_NAME" ip link set dev "$VETH_CONT" up
sudo docker exec "$CONT_NAME" ip addr add "$IP_CIDR" dev "$VETH_CONT"
sudo docker exec "$CONT_NAME" ip route add default via "$GATEWAY"

echo "[OK] Contenedor '${CONT_NAME}' con IP ${IP_CIDR}, gw ${GATEWAY} (VLAN ${VLAN_ID})."
