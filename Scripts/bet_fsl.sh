#!/bin/bash


ROOT_DIR="/home/ahmed/College/flanker_test/ds102_R2.0.0_all_data/ds102_R2.0.0"
THRESHOLD=0.3


for id in `seq -w 1 26` ; do
    subj="sub-$id"
    echo "===> Starting processing of $subj"
    echo
    
    if [ ! -d "${ROOT_DIR}/${subj}" ]; then
        echo "Error: Directory ${ROOT_DIR}/${subj} does not exist, skipping..."
        continue
    fi
    
    input_file="${ROOT_DIR}/${subj}/anat/${subj}_T1w.nii.gz"
    if [ ! -f "${input_file}" ]; then
        echo "Error: Input file ${input_file} does not exist, skipping..."
        continue
    fi
    
    output_file="${ROOT_DIR}/${subj}/anat/${subj}_T1w_brain_f${THRESHOLD}.nii.gz"
    
    for existing_file in "${ROOT_DIR}/${subj}/anat/${subj}_T1w_brain_f*.nii.gz"; do
        if [ -f "${existing_file}" ] && [ "${existing_file}" != "${output_file}" ]; then
            echo "Found existing brain mask with different threshold: ${existing_file}"
            echo "Removing ${existing_file}..."
            rm -f "${existing_file}"
        fi
    done
    
    if [ ! -f "${output_file}" ]; then
        echo "Skull-stripped brain not found, using bet with a fractional intensity threshold of ${THRESHOLD}"
        
        bet2 "${input_file}" "${output_file}" -f ${THRESHOLD}
        if [ $? -ne 0 ]; then
            echo "Error: bet2 failed for ${subj}, skipping..."
            continue
        fi
    else
        echo "Brain mask with threshold ${THRESHOLD} already exists: ${output_file}"
    fi
    
    cd "${ROOT_DIR}" || {
        echo "Error: Could not return to ${ROOT_DIR}, exiting..."
        exit 1
    }
done