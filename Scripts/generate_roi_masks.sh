#!/bin/bash

# Use the current working directory
OUTPUT_DIR="./roi_analysis"

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Hard coded clusters
declare -a COPE_1_CLUSTERS=(
    "64.0 52.0 69.0"
    "63.0 89.0 45.0"
    "32.0 96.0 31.0"
    "21.0 49.0 32.0"
)

declare -a COPE_2_CLUSTERS=(
    "65.0 52.0 69.0"
    "25.0 85.0 49.0"
    "30.0 93.0 28.0"
    "21.0 49.0 32.0"
)

declare -a COPE_3_CLUSTERS=(
    "30.0 26.0 60.0"
    "68.0 26.0 30.0"
    "19.0 28.0 33.0"
    "20.0 66.0 45.0"
)

for cope in {1..3}; do
    echo "Processing COPE ${cope}..."

    if [ ${cope} -eq 1 ]; then
        CLUSTERS=("${COPE_1_CLUSTERS[@]}")
    elif [ ${cope} -eq 2 ]; then
        CLUSTERS=("${COPE_2_CLUSTERS[@]}")
    else
        CLUSTERS=("${COPE_3_CLUSTERS[@]}")
    fi

    cluster_idx=1
    for cluster in "${CLUSTERS[@]}"; do
        # Extract x, y, z coordinates from the cluster
        read x y z <<< "${cluster}"
        echo "  Creating ROI mask for cluster ${cluster_idx} at (${x}, ${y}, ${z})"

        # Define output mask file and input allzstat file
        mask_file="${OUTPUT_DIR}/cope${cope}_cluster${cluster_idx}_5mm_mask.nii.gz"

        # Step 1: Create a single-voxel ROI
        fslmaths $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -mul 0 -add 1 -roi ${x} 1 ${y} 1 ${z} 1 0 1 "${mask_file}" -odt float

        # Step 2: Apply 5mm spherical kernel
        fslmaths "${mask_file}" -kernel sphere 5 -fmean "${mask_file}" -odt float

        # Step 3: Binarize the mask
        fslmaths "${mask_file}" -bin "${mask_file}"

        echo "  Mask created at ${mask_file}"
        ((cluster_idx++))
    done
done

echo "ROI mask creation complete!"