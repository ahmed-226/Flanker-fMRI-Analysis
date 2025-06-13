#!/bin/bash


INPUT_FILE="sub-01_T1w.nii.gz"

# Check if input file exists
if [ ! -f "${INPUT_FILE}" ]; then
    echo "Error: Input file ${INPUT_FILE} not found in current directory"
    exit 1
fi

echo "===> Starting BET processing for ${INPUT_FILE}"

# Loop through fractional intensity thresholds from 0.1 to 0.9
for threshold in $(seq 0.1 0.1 0.9); do
    threshold_str=$(printf "f%02d" $(echo "$threshold * 10" | bc | cut -d. -f1))
    OUTPUT_FILE="sub-01_T1w_brain_${threshold_str}.nii.gz"

    if [ -f "${OUTPUT_FILE}" ]; then
        echo "Output file ${OUTPUT_FILE} already exists, skipping threshold ${threshold}"
        continue
    fi

    echo "Running BET with fractional intensity threshold ${threshold}"
    bet2 "${INPUT_FILE}" "${OUTPUT_FILE}" -f "${threshold}"
    
    if [ $? -ne 0 ]; then
        echo "Error: bet2 failed for threshold ${threshold}"
    else
        echo "Successfully created ${OUTPUT_FILE}"
    fi
done

echo "===> Completed BET processing for ${INPUT_FILE}"
