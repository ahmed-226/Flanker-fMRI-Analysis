#!/bin/bash

# Use the current directory (roi_analysis)
OUTPUT_DIR="."

# Check if allzstats files exist in the current directory
for cope in {1..3}; do
    if [ ! -f "./allZstats_cope${cope}.nii.gz" ]; then
        echo "Error: File ./allZstats_cope${cope}.nii.gz not found in $(pwd)"
        echo "Please verify the file names and ensure they are in the current directory."
        echo "Directory contents:"
        ls -l
        exit 1
    fi
done

# Loop over all mask files in the current directory
for mask_file in ./*_mask.nii.gz; do
    # Skip if no mask files found
    [ -e "${mask_file}" ] || continue

    # Extract cope number and cluster number from the mask file name
    # Example: cope1_cluster1_5mm_mask.nii.gz -> cope=1, cluster=1
    cope=$(echo "${mask_file}" | grep -o 'cope[0-9]' | grep -o '[0-9]')
    cluster=$(echo "${mask_file}" | grep -o 'cluster[0-9]' | grep -o '[0-9]')

    if [ -z "${cope}" ] || [ -z "${cluster}" ]; then
        echo "Warning: Skipping invalid mask file name ${mask_file}"
        continue
    fi

    echo "Processing mask ${mask_file} for COPE ${cope}, Cluster ${cluster}"

    # Define output data file
    output_data="./cope${cope}_cluster${cluster}_data.txt"
    allzstats_file="./allZstats_cope${cope}.nii.gz"

    # Use fslmeants to extract data
    fslmeants -i "${allzstats_file}" -o "${output_data}" -m "${mask_file}"

    echo "  Data extracted to ${output_data}"
done

echo "Data extraction complete!"
