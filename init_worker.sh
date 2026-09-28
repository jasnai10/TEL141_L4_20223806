#!/bin/bash

set -euo pipefail

BRIDGE="br-int"

if [ "$#" -lt 1 ]; then
    echo "[ERROR] Debe indicar al menos una interfaz para conectar al bridge."
    echo "Uso: $0 <iface1> [iface2] ..."
    exit 1
fi

# 1. Crear el bridge si no existe.
echo "[INFO] Verificando/creando el bridge OVS '$BRIDGE'..."
sudo ovs-vsctl --may-exist add-br "$BRIDGE"

# 2. Conectar las interfaces provistas.
for IFACE in "$@"; do
    echo "[INFO] Conectando la interfaz '$IFACE' al bridge '$BRIDGE'..."
    sudo ovs-vsctl --may-exist add-port "$BRIDGE" "$IFACE"
    sudo ip link set dev "$IFACE" up
done

echo "[OK] Nodo worker inicializado correctamente."