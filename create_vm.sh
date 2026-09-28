#!/bin/bash

set -euo pipefail

if [ "$#" -ne 4 ]; then
    echo "[ERROR] Parametros insuficientes."
    echo "Uso: $0 <nombre_vm> <bridge> <vlan_id> <vnc_display>"
    exit 1
fi

VM_NAME="$1"
BRIDGE="$2"
VLAN_ID="$3"
VNC_DISPLAY="$4"

# ---------------------------------------------------------------------------
# Parametros derivados
# ---------------------------------------------------------------------------
TAP_NAME="${VM_NAME}_tap"                 
IMG_NAME="${VM_NAME}_img.qcow2"                 
BASE_IMG="cirros-0.5.1-x86_64-disk.img"         
BASE_URL="http://download.cirros-cloud.net/0.5.1/${BASE_IMG}"


PUCP_PREFIX="20:22:38:06"                
VLAN_OCTET=$(printf '%02x' "$((VLAN_ID % 256))")
MAC="${PUCP_PREFIX}:${VLAN_OCTET}:00"


# 1. Disco de arranque: detectar imagen base; si no existe, descargarla.

if [ ! -f "$BASE_IMG" ]; then
    echo "[INFO] Imagen base no encontrada. Descargando ${BASE_IMG}..."
    wget -q "$BASE_URL" -O "$BASE_IMG"
    echo "[OK] Imagen base descargada."
else
    echo "[INFO] Imagen base '${BASE_IMG}' ya existe."
fi


if [ ! -f "$IMG_NAME" ]; then
    echo "[INFO] Creando imagen diferencial '${IMG_NAME}' con backing file..."
    qemu-img create -f qcow2 -b "$BASE_IMG" -F qcow2 "$IMG_NAME"
else
    echo "[INFO] La imagen '${IMG_NAME}' ya existe."
fi


# 2. Crear la interfaz TAP y conectarla al OVS en la VLAN indicada.

echo "[INFO] Creando interfaz TAP '${TAP_NAME}'..."
sudo ip tuntap add mode tap name "$TAP_NAME" 2>/dev/null || true
sudo ovs-vsctl --may-exist add-port "$BRIDGE" "$TAP_NAME" tag="$VLAN_ID"
sudo ip link set dev "$TAP_NAME" up


# 3. Arrancar la VM con QEMU/KVM.

echo "[INFO] Iniciando la VM '${VM_NAME}' (VLAN ${VLAN_ID}, VNC :${VNC_DISPLAY}, MAC ${MAC})..."
sudo qemu-system-x86_64 \
    -enable-kvm \
    -vnc "0.0.0.0:${VNC_DISPLAY}" \
    -netdev tap,id=tap1,ifname="$TAP_NAME",script=no,downscript=no \
    -device e1000,netdev=tap1,mac="$MAC" \
    -daemonize \
    "$IMG_NAME"

echo "[OK] VM '${VM_NAME}' creada y en ejecucion (VNC en el puerto $((5900 + VNC_DISPLAY)))."