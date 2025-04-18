#!/bin/bash
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in "$g"/devices/*; do
        echo -e "\t$(lspci -n -s "${d##*/}")\t$(lspci -k -s "${d##*/}")"
    done
done
shopt -u nullglob
