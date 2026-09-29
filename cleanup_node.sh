#!/bin/bash

echo "===== LIMPIEZA DEL NODO: $(hostname) ====="

# 1. Detener todas las VMs (procesos QEMU)
PIDS=$(sudo ps aux | grep qemu-system | grep -v grep | awk '{print $2}')
if [ -n "$PIDS" ]; then
    for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done
fi

# 2. Detener y eliminar contenedores docker
if command -v docker >/dev/null 2>&1; then
    CONTS=$(sudo docker ps -aq)
    if [ -n "$CONTS" ]; then
        sudo docker rm -f $CONTS 2>/dev/null || true
    fi
fi

# 3. Detener procesos dnsmasq
sudo pkill dnsmasq 2>/dev/null || true

# 4. Eliminar network namespaces
for ns in $(ip netns list 2>/dev/null | awk '{print $1}'); do
    sudo ip netns del "$ns" 2>/dev/null || true
done

# 5. Eliminar el bridge OVS 'br-int'
sudo ovs-vsctl --if-exists del-br br-int

# 6. Eliminar interfaces TAP y veth residuales
for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -E 'tap|veth' || true); do
    name="${iface%@*}"
    sudo ip link del "$name" 2>/dev/null || true
done

# 7. Limpiar reglas de iptables y restaurar politicas
sudo iptables -t nat -F
sudo iptables -F FORWARD
sudo iptables -P FORWARD ACCEPT

echo "===== LIMPIEZA COMPLETADA EN: $(hostname) ====="
