#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

S1="ubuntu@10.0.10.1"
S2="ubuntu@10.0.10.2"
S3="ubuntu@10.0.10.3"

DATA_IF="ens4"
EXT_IF="ens3"

VLAN100="100"
CIDR100="192.168.0.0/24"
GW100="192.168.0.1"
CONT_IP100="192.168.0.10/24"

VLAN200="200"
CIDR200="192.168.2.0/24"

# 1. Limpiar los 3 nodos
echo "########## 1. LIMPIEZA DE LOS NODOS ##########"
ssh "$S1" 'bash -s' < "$BASE_DIR/cleanup_node.sh"
ssh "$S2" 'bash -s' < "$BASE_DIR/cleanup_node.sh"
ssh "$S3" 'bash -s' < "$BASE_DIR/cleanup_node.sh"

# 2. Inicializar el master (server 3)
echo "########## 2. INICIALIZAR EL MASTER (server 3) ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/init_master.sh" "$DATA_IF"

# 3. Inicializar los workers (server 1 y 2)
echo "########## 3. INICIALIZAR LOS WORKERS (server 1 y 2) ##########"
ssh "$S1" 'bash -s' < "$BASE_DIR/init_worker.sh" "$DATA_IF"
ssh "$S2" 'bash -s' < "$BASE_DIR/init_worker.sh" "$DATA_IF"

# 4. Crear VLAN 100 SIN DHCP
echo "########## 4. CREAR VLAN 100 SIN DHCP ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/create_network_vlan.sh" "$VLAN100" "$CIDR100" off

# 5. Crear VLAN 200 SIN DHCP
echo "########## 5. CREAR VLAN 200 SIN DHCP ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/create_network_vlan.sh" "$VLAN200" "$CIDR200" off

# 6. Salida a Internet para VLAN 100
echo "########## 6. SALIDA A INTERNET PARA VLAN 100 ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/internet_to_network.sh" "$VLAN100" "$CIDR100" "$EXT_IF"

# 7. Salida a Internet para VLAN 200
echo "########## 7. SALIDA A INTERNET PARA VLAN 200 ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/internet_to_network.sh" "$VLAN200" "$CIDR200" "$EXT_IF"

# 8. Crear contenedor en server 1 (VLAN 100) con IP MANUAL
echo "########## 8. CREAR CONTENEDOR EN SERVER 1 (VLAN 100, IP MANUAL) ##########"
ssh "$S1" 'bash -s' < "$BASE_DIR/create_container_static.sh" cont_s1_v100 br-int "$VLAN100" "$CONT_IP100" "$GW100"

# 9. Crear VM en server 2 (VLAN 100) - la IP se configura por VNC
echo "########## 9. CREAR VM EN SERVER 2 (VLAN 100) ##########"
ssh "$S2" 'bash -s' < "$BASE_DIR/create_vm.sh" vm_s2_v100 br-int "$VLAN100" 1

echo "########## DESPLIEGUE DE LA ACTIVIDAD 2 COMPLETADO ##########"
echo "NOTA: a la VM del server 2 asignarle IP manual por VNC:"
echo "  sudo ip addr add 192.168.0.20/24 dev eth0"
echo "  sudo ip route add default via 192.168.0.1"
