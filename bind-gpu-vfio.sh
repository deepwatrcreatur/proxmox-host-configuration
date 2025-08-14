#!/bin/bash
set -e

echo "Starting GPU VFIO binding..."

# Load VFIO modules first
modprobe vfio-pci

# The GPU isn't bound to any driver currently, so we can skip unbinding
# and go straight to binding with vfio-pci

# Check if IDs are already registered (ignore if they exist)
echo "Binding GPU to vfio-pci..."
echo 1002 73ff > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
echo 1002 ab28 > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true

# Force bind the specific devices
echo 0000:08:00.0 > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || true
echo 0000:08:00.1 > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || true

echo "GPU binding complete"

# Verify the binding worked
if lspci -k -s 08:00.0 | grep -q "vfio-pci"; then
    echo "Success: GPU bound to vfio-pci"
else
    echo "Warning: GPU may not be properly bound"
fi
