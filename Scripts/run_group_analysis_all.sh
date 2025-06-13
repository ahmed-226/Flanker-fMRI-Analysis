#!/bin/bash

BASE_DIR="/home/ahmed/College/flanker_test/ds102_R2.0.0_all_data/ds102_R2.0.0"
OUTPUT_DIR="${BASE_DIR}/group_analysis.gfeat"
LOGS_DIR="${OUTPUT_DIR}/logs"
FSLDIR="/home/ahmed/fsl"
NUM_SUBJECTS=26
NUM_COPES=3

echo "Starting full group analysis..."

# Create directories
mkdir -p ${OUTPUT_DIR}
mkdir -p ${LOGS_DIR}
mkdir -p ${OUTPUT_DIR}/.files

# Copy CSS and images for web reports
cp ${FSLDIR}/doc/fsl.css ${OUTPUT_DIR}/.files
cp -r ${FSLDIR}/doc/images ${OUTPUT_DIR}/.files/images

# Process each subject's run through featregapply
echo "Running featregapply for all subjects..."
for SUB in $(seq -w 01 ${NUM_SUBJECTS}); do
    for RUN in 1 2; do
        FEAT_DIR="${BASE_DIR}/sub-${SUB}/run${RUN}.feat"
        if [ -d "${FEAT_DIR}" ]; then
            echo "Processing ${FEAT_DIR}"
            ${FSLDIR}/bin/featregapply ${FEAT_DIR} >> ${LOGS_DIR}/featregapply.log 2>&1
        else
            echo "Warning: ${FEAT_DIR} does not exist"
        fi
    done
done

# Copy the working FSF file from your successful run and update it
echo "Setting up design files..."
# First create a backup of the original
mkdir -p ${BASE_DIR}/backup
cp ${BASE_DIR}/outout.gfeat/design.* ${BASE_DIR}/backup/

# Now modify the FSF file for all subjects
cp ${BASE_DIR}/outout.gfeat/design.fsf ${OUTPUT_DIR}/design.fsf

# Update output directory in the FSF file
sed -i "s|set fmri(outputdir) \".*\"|set fmri(outputdir) \"${OUTPUT_DIR}\"|g" ${OUTPUT_DIR}/design.fsf

# Create design matrix using the FSF file
echo "Creating design matrix..."
cd ${OUTPUT_DIR}
${FSLDIR}/bin/feat_model design >> ${LOGS_DIR}/feat_model.log 2>&1

# Merge background images from all subjects
echo "Merging background images..."
BG_FILES=""
for SUB in $(seq -w 01 ${NUM_SUBJECTS}); do
    for RUN in 1 2; do
        HIGHRES="${BASE_DIR}/sub-${SUB}/run${RUN}.feat/reg_standard/reg/highres"
        if [ -f "${HIGHRES}" ]; then
            BG_FILES="${BG_FILES} ${HIGHRES}"
        fi
    done
done

if [ -n "${BG_FILES}" ]; then
    ${FSLDIR}/bin/fslmerge -t ${OUTPUT_DIR}/bg_image ${BG_FILES}
    ${FSLDIR}/bin/fslmaths ${OUTPUT_DIR}/bg_image -inm 1000 -Tmean ${OUTPUT_DIR}/bg_image -odt float
fi

# Merge mask images
echo "Merging masks..."
MASK_FILES=""
for SUB in $(seq -w 01 ${NUM_SUBJECTS}); do
    for RUN in 1 2; do
        MASK="${BASE_DIR}/sub-${SUB}/run${RUN}.feat/reg_standard/mask"
        if [ -f "${MASK}" ]; then
            MASK_FILES="${MASK_FILES} ${MASK}"
        fi
    done
done

if [ -n "${MASK_FILES}" ]; then
    ${FSLDIR}/bin/fslmerge -t ${OUTPUT_DIR}/mask ${MASK_FILES}
    ${FSLDIR}/bin/fslmaths ${OUTPUT_DIR}/mask -Tmin ${OUTPUT_DIR}/mask
fi

# Create mean functional image
echo "Creating mean functional image..."
FUNC_FILES=""
for SUB in $(seq -w 01 ${NUM_SUBJECTS}); do
    for RUN in 1 2; do
        FUNC="${BASE_DIR}/sub-${SUB}/run${RUN}.feat/reg_standard/mean_func"
        if [ -f "${FUNC}" ]; then
            FUNC_FILES="${FUNC_FILES} ${FUNC}"
        fi
    done
done

if [ -n "${FUNC_FILES}" ]; then
    ${FSLDIR}/bin/fslmerge -t ${OUTPUT_DIR}/mean_func ${FUNC_FILES}
    ${FSLDIR}/bin/fslmaths ${OUTPUT_DIR}/mean_func -Tmean ${OUTPUT_DIR}/mean_func
fi

# Create inputreg directory as in your logs
mkdir -p ${OUTPUT_DIR}/inputreg

# Calculate mask sum
echo "Calculating mask sum..."
${FSLDIR}/bin/fslmaths ${OUTPUT_DIR}/mask -mul $(( NUM_SUBJECTS * 2 )) -Tmean ${OUTPUT_DIR}/masksum -odt short
${FSLDIR}/bin/fslmaths ${OUTPUT_DIR}/masksum -thr $(( NUM_SUBJECTS * 2 )) -add ${OUTPUT_DIR}/masksum ${OUTPUT_DIR}/masksum

# Create overlay visualization
${FSLDIR}/bin/overlay 0 0 -c ${OUTPUT_DIR}/bg_image -a ${OUTPUT_DIR}/masksum 0.9 8 ${OUTPUT_DIR}/masksum_overlay
${FSLDIR}/bin/slicer ${OUTPUT_DIR}/masksum_overlay -S 2 750 ${OUTPUT_DIR}/masksum_overlay.png

# Process each contrast as in your logs
for COPE in $(seq 1 ${NUM_COPES}); do
    echo "Processing cope${COPE}..."
    
    # Merge cope files
    COPE_FILES=""
    for SUB in $(seq -w 01 ${NUM_SUBJECTS}); do
        for RUN in 1 2; do
            COPE_FILE="${BASE_DIR}/sub-${SUB}/run${RUN}.feat/reg_standard/stats/cope${COPE}"
            if [ -f "${COPE_FILE}" ]; then
                COPE_FILES="${COPE_FILES} ${COPE_FILE}"
            fi
        done
    done
    
    if [ -n "${COPE_FILES}" ]; then
        ${FSLDIR}/bin/fslmerge -t ${OUTPUT_DIR}/cope${COPE} ${COPE_FILES}
        ${FSLDIR}/bin/fslmaths ${OUTPUT_DIR}/cope${COPE} -mas ${OUTPUT_DIR}/mask ${OUTPUT_DIR}/cope${COPE}
    fi
    
    # Get contrast values from the original successful run (assuming they're in a .lcon file)
    if [ -f "${BASE_DIR}/outout.gfeat/design.lcon" ]; then
        CONTRAST=$(grep -o "[0-9]*\.[0-9]*" ${BASE_DIR}/outout.gfeat/design.lcon | sed -n "${COPE}p")
        if [ -n "${CONTRAST}" ]; then
            echo "Adding contrast value ${CONTRAST} to design.lcon"
            printf "${CONTRAST} " >> ${OUTPUT_DIR}/design.lcon
        fi
    fi
    
    # Merge varcope files
    VARCOPE_FILES=""
    for SUB in $(seq -w 01 ${NUM_SUBJECTS}); do
        for RUN in 1 2; do
            VARCOPE_FILE="${BASE_DIR}/sub-${SUB}/run${RUN}.feat/reg_standard/stats/varcope${COPE}"
            if [ -f "${VARCOPE_FILE}" ]; then
                VARCOPE_FILES="${VARCOPE_FILES} ${VARCOPE_FILE}"
            fi
        done
    done
    
    if [ -n "${VARCOPE_FILES}" ]; then
        ${FSLDIR}/bin/fslmerge -t ${OUTPUT_DIR}/varcope${COPE} ${VARCOPE_FILES}
        ${FSLDIR}/bin/fslmaths ${OUTPUT_DIR}/varcope${COPE} -mas ${OUTPUT_DIR}/mask ${OUTPUT_DIR}/varcope${COPE}
    fi
    
    # Create and merge tdof files
    for SUB in $(seq -w 01 ${NUM_SUBJECTS}); do
        for RUN in 1 2; do
            STATS_DIR="${BASE_DIR}/sub-${SUB}/run${RUN}.feat/reg_standard/stats"
            if [ -d "${STATS_DIR}" ]; then
                # Use 143 degrees of freedom as in your logs
                ${FSLDIR}/bin/fslmaths ${STATS_DIR}/cope${COPE} -mul 0 -add 143 ${STATS_DIR}/FEtdof_t${COPE}
            fi
        done
    done
    
    # Merge tdof files
    TDOF_FILES=""
    for SUB in $(seq -w 01 ${NUM_SUBJECTS}); do
        for RUN in 1 2; do
            TDOF_FILE="${BASE_DIR}/sub-${SUB}/run${RUN}.feat/reg_standard/stats/FEtdof_t${COPE}"
            if [ -f "${TDOF_FILE}" ]; then
                TDOF_FILES="${TDOF_FILES} ${TDOF_FILE}"
            fi
        done
    done
    
    if [ -n "${TDOF_FILES}" ]; then
        ${FSLDIR}/bin/fslmerge -t ${OUTPUT_DIR}/tdof_t${COPE} ${TDOF_FILES}
        ${FSLDIR}/bin/fslmaths ${OUTPUT_DIR}/tdof_t${COPE} -mas ${OUTPUT_DIR}/mask ${OUTPUT_DIR}/tdof_t${COPE}
    fi
done

# Run FEAT preprocessing
echo "Running FEAT preprocessing..."
${FSLDIR}/bin/fsl_sub -T 60 -l ${LOGS_DIR} -N feat2_pre ${FSLDIR}/bin/feat ${OUTPUT_DIR}/design.fsf -D ${OUTPUT_DIR} -gfeatprep

# Wait for preprocessing to complete
echo "Waiting for preprocessing to complete..."
sleep 30  # Give time for the job to start

# Check if preprocessing is complete
PREPROC_JOB=$(ls -t ${LOGS_DIR}/feat2_pre.* 2>/dev/null | head -1)
if [ -n "${PREPROC_JOB}" ]; then
    PREPROC_JOBID=$(basename ${PREPROC_JOB} | cut -d '.' -f 2)
    echo "Preprocessing job ID: ${PREPROC_JOBID}"
else
    echo "No preprocessing job found. Using a delay instead."
    sleep 300  # Wait 5 minutes for preprocessing to potentially complete
fi

# Run FEAT analysis for each contrast
for COPE in $(seq 1 ${NUM_COPES}); do
    echo "Running analysis for cope${COPE}..."
    
    # Run FLAME1
    FLAME1_JOB=$(${FSLDIR}/bin/fsl_sub -T 60 -l ${LOGS_DIR} -N feat3a_flame -j ${PREPROC_JOBID} ${FSLDIR}/bin/feat ${OUTPUT_DIR}/design.fsf -D ${OUTPUT_DIR}/cope${COPE}.feat -I ${COPE} -flame1)
    echo "FLAME1 job ID for cope${COPE}: ${FLAME1_JOB}"
    
    # Run FLAME temporary step
    FLAME_TEMP_JOB=$(${FSLDIR}/bin/fsl_sub -T 60 -l ${LOGS_DIR} -N feat3b_flame -j ${FLAME1_JOB} -t ${OUTPUT_DIR}/.flame)
    echo "FLAME temp job ID for cope${COPE}: ${FLAME_TEMP_JOB}"
    
    # Run FLAME3
    FLAME3_JOB=$(${FSLDIR}/bin/fsl_sub -T 60 -l ${LOGS_DIR} -N feat3c_flame -j ${FLAME_TEMP_JOB} ${FSLDIR}/bin/feat ${OUTPUT_DIR}/design.fsf -D ${OUTPUT_DIR}/cope${COPE}.feat -flame3)
    echo "FLAME3 job ID for cope${COPE}: ${FLAME3_JOB}"
    
    # Run post-stats
    POST_JOB=$(${FSLDIR}/bin/fsl_sub -T 60 -l ${LOGS_DIR} -N feat4_post -j ${FLAME3_JOB} ${FSLDIR}/bin/feat ${OUTPUT_DIR}/design.fsf -D ${OUTPUT_DIR}/cope${COPE}.feat -poststats 1)
    echo "Post-stats job ID for cope${COPE}: ${POST_JOB}"
    
    # Run stop
    STOP_JOB=$(${FSLDIR}/bin/fsl_sub -T 1 -l ${LOGS_DIR} -N feat5_stop -j ${POST_JOB} ${FSLDIR}/bin/feat ${OUTPUT_DIR}/design.fsf -D ${OUTPUT_DIR}/cope${COPE}.feat -stop)
    echo "Stop job ID for cope${COPE}: ${STOP_JOB}"
    
    # Store the stop job ID
    STOP_JOBS="${STOP_JOBS},${STOP_JOB}"
done

# Remove leading comma if present
STOP_JOBS=$(echo ${STOP_JOBS} | sed 's/^,//')

# Final stop for all contrasts
FINAL_STOP=$(${FSLDIR}/bin/fsl_sub -T 1 -l ${LOGS_DIR} -N feat5_stop -j ${STOP_JOBS} ${FSLDIR}/bin/feat ${OUTPUT_DIR}/design.fsf -D ${OUTPUT_DIR} -stop)
echo "Final stop job ID: ${FINAL_STOP}"

echo "Group analysis job submitted. Check logs in ${LOGS_DIR}"
echo "To monitor progress: cat ${LOGS_DIR}/*.o*"
echo "The analysis may take some time to complete."