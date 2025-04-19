#!/bin/bash

# --- Configuration ---
DEST_USER="root"
DEST_IP="10.10.11.57"
DEST_BASE_DIR="/mnt/pve/fast/lvm_backups" # MUST exist on the destination Mac
SOURCE_VG="pve"                  # Proxmox Volume Group name
BLOCK_SIZE="1M"                  # dd block size (1M is usually good)

# List of LVM volumes to copy (based on your ls output)
# Add or remove lines here if needed
LVS_TO_COPY=(
    "vm-100-disk-0"
    "vm-101-disk-2"
    "vm-102-disk-0"
    "vm-103-disk-0"
    "vm-103-disk-1"
    "vm-10443-disk-0"
    "vm-10443-disk-1"
    "vm-106-disk-0"
)

# --- Script Logic ---
echo "Starting LVM volume copy process..."
echo "Source VG: /dev/${SOURCE_VG}"
echo "Destination: ${DEST_USER}@${DEST_IP}:${DEST_BASE_DIR}"
echo "Block Size: ${BLOCK_SIZE}"
echo "---"

# Ensure destination base directory exists (basic check via ssh)
# This requires ssh to work. If it fails, the script will still try,
# but the dd commands on the remote end will likely fail.
if ! ssh "${DEST_USER}@${DEST_IP}" "[ -d \"${DEST_BASE_DIR}\" ]"; then
   echo "ERROR: Destination directory '${DEST_BASE_DIR}' does not seem to exist on ${DEST_IP} or SSH connection failed."
   echo "Please create the directory manually and ensure SSH access works."
   # exit 1 # Optional: uncomment to stop the script if dir check fails
fi


# Loop through the specified LVM volumes
for lv_name in "${LVS_TO_COPY[@]}"; do
    source_path="/dev/${SOURCE_VG}/${lv_name}"
    dest_filename="${lv_name}.img" # Saving as raw image files
    dest_full_path="${DEST_BASE_DIR}/${dest_filename}"

    echo ">>> Processing Volume: ${lv_name}"
    echo "    Source: ${source_path}"
    echo "    Target: ${DEST_USER}@${DEST_IP}:${dest_full_path}"

    # Check if source LV exists as a block device
    if [ ! -b "${source_path}" ]; then
        echo "    ERROR: Source LV ${source_path} does not exist or is not a block device. Skipping."
        echo "---"
        continue # Skip to the next LV in the loop
    fi

    # Construct the dd command
    # Using status=progress requires a relatively modern version of dd
    # Quoting is important for the remote command

    # Construct the remote command separately
    remote_cmd="dd of=\"${dest_full_path}\" bs=\"${BLOCK_SIZE}\""

    echo "    Executing: dd if=\"${source_path}\" bs=\"${BLOCK_SIZE}\" status=progress | ssh \"${DEST_USER}@${DEST_IP}\" \"${remote_cmd}\""

    # Execute the command without eval
    dd if="${source_path}" bs="${BLOCK_SIZE}" status=progress | ssh "${DEST_USER}@${DEST_IP}" "${remote_cmd}"

    # Capture exit statuses immediately
    local_dd_status=${PIPESTATUS[0]}
    remote_ssh_dd_status=${PIPESTATUS[1]}

    # Capture exit statuses immediately
    local_dd_status=${PIPESTATUS[0]}
    remote_ssh_dd_status=${PIPESTATUS[1]}

    # Check if BOTH commands succeeded (exit code 0)
    # Use parameter expansion ${remote_ssh_dd_status:-1} to default an empty status to 1 (non-zero)
    # This prevents the "integer expression expected" error and treats empty status as failure.
    if [ "${local_dd_status}" -eq 0 ] && [ "${remote_ssh_dd_status:-1}" -eq 0 ]; then
        echo "    SUCCESS: Successfully copied ${lv_name}."
    else
        # Determine if the failure was local dd or remote/unknown
        if [ "${local_dd_status}" -ne 0 ]; then
             echo "    ERROR: Local dd failed for ${lv_name}."
             echo "           Local dd exit code: ${local_dd_status}"
             echo "           SSH/Remote dd exit code: ${remote_ssh_dd_status:-(unknown)}"
        else
             # Local dd was OK (0), so the issue is remote or status capture
             echo "    WARNING: Local dd successful, but remote SSH/dd exit status is non-zero or unknown (${remote_ssh_dd_status:-(unknown)})."
             echo "             >> Recommend verifying file integrity on destination: ${dest_full_path}"
        fi
    fi
    echo "---"
done

echo "All specified LVM copy tasks attempted."
echo "Don't forget to also copy the VM configuration files from /etc/pve/qemu-server/ !"

