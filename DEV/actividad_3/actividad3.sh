#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

S1="ubuntu@10.0.10.1"
S2="ubuntu@10.0.10.2"
S3="ubuntu@10.0.10.3"

DATA_IF="ens4"

VLAN100="100"
CIDR100="192.168.0.0/24"
RANGE100_INI="192.168.0.11"
RANGE100_FIN="192.168.0.15"

VLAN200="200"
CIDR200="192.168.2.0/24"
RANGE200_INI="192.168.2.11"
RANGE200_FIN="192.168.2.15"

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

# 4. Crear VLAN 100 CON DHCP
echo "########## 4. CREAR VLAN 100 CON DHCP ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/create_network_vlan.sh" "$VLAN100" "$CIDR100" on "$RANGE100_INI" "$RANGE100_FIN"

# 5. Crear VLAN 200 CON DHCP
echo "########## 5. CREAR VLAN 200 CON DHCP ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/create_network_vlan.sh" "$VLAN200" "$CIDR200" on "$RANGE200_INI" "$RANGE200_FIN"

# NOTA: NO se ejecuta internet_to_network.sh -> redes SIN salida a Internet

# 6. Crear contenedor en server 1 (VLAN 100) con IP por DHCP
echo "########## 6. CREAR CONTENEDOR EN SERVER 1 (VLAN 100, DHCP) ##########"
ssh "$S1" 'bash -s' < "$BASE_DIR/create_container.sh" cont_s1_v100 br-int "$VLAN100"

# 7. Crear VM en server 2 (VLAN 100) - la IP se pide por DHCP via VNC
echo "########## 7. CREAR VM EN SERVER 2 (VLAN 100) ##########"
ssh "$S2" 'bash -s' < "$BASE_DIR/create_vm.sh" vm_s2_v100 br-int "$VLAN100" 1

echo "########## DESPLIEGUE DE LA ACTIVIDAD 3 COMPLETADO ##########"
echo "NOTA: redes CON DHCP pero SIN salida a Internet (no hay NAT)."
echo "En la VM del server 2, pedir IP por DHCP via VNC: sudo udhcpc -i eth0"
