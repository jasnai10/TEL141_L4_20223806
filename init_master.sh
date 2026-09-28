#!/bin/bash

set -euo pipefail

BRIDGE="br-int"


# Validacion de parametros de entrada

if [ "$#" -lt 1 ]; then
    echo "[ERROR] Debe indicar al menos una interfaz para conectar al bridge."
    echo "Uso: $0 <iface1> [iface2] ..."
    exit 1
fi


# 1. Crear el bridge OVS 'br-int' si no existe


echo "[INFO] Verificando/creando el bridge OVS '$BRIDGE'..."
sudo ovs-vsctl --may-exist add-br "$BRIDGE"


# 2. Conectar las interfaces provistas al bridge

for IFACE in "$@"; do
    echo "[INFO] Conectando la interfaz '$IFACE' al bridge '$BRIDGE'..."
    # --may-exist evita error si el puerto ya estaba agregado.
    sudo ovs-vsctl --may-exist add-port "$BRIDGE" "$IFACE"
    # Activar la interfaz por si estuviera caida.
    sudo ip link set dev "$IFACE" up
done


# 3. Activar el IPv4 forwarding

echo "[INFO] Activando IPv4 forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1


# 4. Cambiar la politica por defecto de la cadena FORWARD a DROP

echo "[INFO] Estableciendo la politica FORWARD (tabla filter) en DROP..."
sudo iptables -P FORWARD DROP

echo "[OK] Nodo master inicializado correctamente."