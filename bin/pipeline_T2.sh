#!/bin/bash

function die {
  echo $1
  exit 1
}

if [ $# != 4 ]
then
  echo "usage: $0 <nifti_image> <json_file> <threshold_value> <output_file_name>"
  exit 1
fi

OUTPUT_FILE=$4

pipeline_T2 $1 $2 $3 || die "Pipeline execution failed!"

zip -r $4 *-T2_Error.nii *-M0_Error.nii *-T2map.nii *-M0map.nii || die "Cannot zip output files!"
