#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

S1="ubuntu@10.0.10.1"
S2="ubuntu@10.0.10.2"
S3="ubuntu@10.0.10.3"

DATA_IF="ens4"
EXT_IF="ens3"

VLAN100="100"
CIDR100="192.168.0.0/24"
RANGE100_INI="192.168.0.11"
RANGE100_FIN="192.168.0.15"

VLAN200="200"
CIDR200="192.168.2.0/24"
RANGE200_INI="192.168.2.11"
RANGE200_FIN="192.168.2.15"

# 1. Inicializar el master (server 3)
echo "########## 1. INICIALIZAR EL MASTER (server 3) ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/init_master.sh" "$DATA_IF"

# 2. Inicializar los workers (server 1 y 2)
echo "########## 2. INICIALIZAR LOS WORKERS (server 1 y 2) ##########"
ssh "$S1" 'bash -s' < "$BASE_DIR/init_worker.sh" "$DATA_IF"
ssh "$S2" 'bash -s' < "$BASE_DIR/init_worker.sh" "$DATA_IF"

# 3. Crear VLAN 100 con DHCP
echo "########## 3. CREAR VLAN 100 CON DHCP ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/create_network_vlan.sh" "$VLAN100" "$CIDR100" on "$RANGE100_INI" "$RANGE100_FIN"

# 4. Crear VLAN 200 con DHCP
echo "########## 4. CREAR VLAN 200 CON DHCP ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/create_network_vlan.sh" "$VLAN200" "$CIDR200" on "$RANGE200_INI" "$RANGE200_FIN"

# 5. Salida a Internet para VLAN 100
echo "########## 5. SALIDA A INTERNET PARA VLAN 100 ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/internet_to_network.sh" "$VLAN100" "$CIDR100" "$EXT_IF"

# 6. Salida a Internet para VLAN 200
echo "########## 6. SALIDA A INTERNET PARA VLAN 200 ##########"
ssh "$S3" 'bash -s' < "$BASE_DIR/internet_to_network.sh" "$VLAN200" "$CIDR200" "$EXT_IF"

echo "########## DESPLIEGUE DE LA ACTIVIDAD 1 COMPLETADO ##########"
