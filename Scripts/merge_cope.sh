#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <cope_number>"
  exit 1
fi

COPE_NUM=$1
OUTPUT_FILE="allZstats_cope${COPE_NUM}.nii.gz"

# Build paths with dynamic cope number
ZSTAT_PATHS=$(ls ~/College/flanker_test/Flanker/2ndlevel/2ndlevel_part1.gfeat/cope${COPE_NUM}.feat/stats/zstat* \
                 ~/College/flanker_test/Flanker/2ndlevel/2ndlevel_part2.gfeat/cope${COPE_NUM}.feat/stats/zstat* | sort -V)

fslmerge -t "$OUTPUT_FILE" $ZSTAT_PATHS
