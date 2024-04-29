#!/bin/bash
#SBATCH --account=rrg-arisvoin
#SBATCH --array=1-83
#SBATCH --nodes=1
#SBATCH --cpus-per-task=40
#SBATCH --ntasks-per-node=1
#SBATCH --time=3:00:00
#SBATCH --job-name ukf
#SBATCH --output=ukf_%j.txt

STUDY="STUDY"
sublist=$SCRATCH/${STUDY}/sublist.txt
# sublist of the form "sub-XXXXXX",ie bids names

index() {
   head -n $SLURM_ARRAY_TASK_ID $sublist \
   | tail -n 1
}

subject=`index`
session="ses-01"
sub_basename="${subject}_${session}"

sing_home=$SCRATCH/${STUDY}/sing_home/${sub_basename}
output_dir=$SCRATCH/${STUDY}/wma/

ukf_img=$SCRATCH/${STUDY}/tigrlab_ukftractography_latest-2021-08-11-e2c9dd79117e.simg

mkdir -p ${sing_home} ${output_dir}

qsiprep_output=$SCRATCH/${STUDY}/qsiprep_single/qsiprep/
subject_dmri="$qsiprep_output/${subject}/${session}/dwi"

echo singularity run \
  -H ${sing_home} \
  -B ${subject_dmri}:/input \
  -B ${output_dir}:/output \
  ${ukf_img} \
    /input \
    $sub_basename \
    /input/${sub_basename}_acq-singleshelldir60b1000_run-1_space-T1w_desc-preproc_dwi.nii.gz \
    /input/${sub_basename}_acq-singleshelldir60b1000_run-1_space-T1w_desc-preproc_dwi.bval \
    /input/${sub_basename}_acq-singleshelldir60b1000_run-1_space-T1w_desc-preproc_dwi.bvec \
    /input/${sub_basename}_acq-singleshelldir60b1000_run-1_space-T1w_desc-brain_mask.nii.gz \
    /output

singularity run \
  -H ${sing_home} \
  -B ${subject_dmri}:/input \
  -B ${output_dir}:/output \
  ${ukf_img} \
    /input \
    $sub_basename \
    /input/${sub_basename}_acq-singleshelldir60b1000_run-1_space-T1w_desc-preproc_dwi.nii.gz \
    /input/${sub_basename}_acq-singleshelldir60b1000_run-1_space-T1w_desc-preproc_dwi.bval \
    /input/${sub_basename}_acq-singleshelldir60b1000_run-1_space-T1w_desc-preproc_dwi.bvec \
    /input/${sub_basename}_acq-singleshelldir60b1000_run-1_space-T1w_desc-brain_mask.nii.gz \
    /output
