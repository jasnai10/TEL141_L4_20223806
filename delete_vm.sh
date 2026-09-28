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
echo "[INFO] Eliminando VM '${VM_NAME}' (bridge=${BRIDGE}, vlan=${VLAN_ID}, vnc=:${VNC_DISPLAY})"

TAP_NAME="${VM_NAME}_tap"
IMG_NAME="${VM_NAME}_img.qcow2"
BASE_IMG="cirros-0.5.1-x86_64-disk.img"


# 1. Detener el proceso QEMU de la VM.


echo "[INFO] Deteniendo el proceso QEMU de '${VM_NAME}'..."
PID=$(sudo ps aux | grep qemu | grep "$IMG_NAME" | grep -v grep | awk '{print $2}' || true)
if [ -n "$PID" ]; then
    sudo kill "$PID" 2>/dev/null || true
    echo "[OK] Proceso QEMU (PID $PID) detenido."
else
    echo "[WARN] No se encontro un proceso QEMU para '${VM_NAME}'."
fi


# 2. Retirar el puerto TAP del OVS y eliminar la interfaz TAP.

echo "[INFO] Eliminando el puerto TAP del OVS y la interfaz..."
sudo ovs-vsctl --if-exists del-port "$BRIDGE" "$TAP_NAME"
sudo ip link del "$TAP_NAME" 2>/dev/null || true


# 3. Eliminar la imagen delta de la VM.

if [ -f "$IMG_NAME" ]; then
    echo "[INFO] Eliminando la imagen delta '${IMG_NAME}'..."
    rm -f "$IMG_NAME"
fi


# 4. Detectar si la imagen base ya no tiene deltas asociadas.

echo "[INFO] Verificando si la imagen base '${BASE_IMG}' aun tiene deltas..."
DELTAS=0
for f in *.qcow2; do
    [ -e "$f" ] || continue
    BACKING=$(qemu-img info "$f" 2>/dev/null | grep "backing file:" | awk '{print $3}' || true)
    if [ "$(basename "${BACKING:-}")" == "$BASE_IMG" ]; then
        DELTAS=$((DELTAS + 1))
    fi
done

if [ "$DELTAS" -eq 0 ] && [ -f "$BASE_IMG" ]; then
    echo "[INFO] La imagen base ya no tiene deltas. Eliminando '${BASE_IMG}'..."
    rm -f "$BASE_IMG"
    echo "[OK] Imagen base eliminada."
else
    echo "[INFO] La imagen base conserva $DELTAS delta(s); no se elimina."
fi

echo "[OK] VM '${VM_NAME}' y sus recursos eliminados."