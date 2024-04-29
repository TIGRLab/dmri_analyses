#!/bin/bash -l

#SBATCH --partition=high-moby
#SBATCH --array=1-83
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=4096
#SBATCH --cpus-per-task=1
#SBATCH --time=8:00:00
#SBATCH --export=ALL
#SBATCH --job-name wma
#SBATCH --output=wma_%j.txt

cd $SLURM_SUBMIT_DIR

# List of ids (without sub- in name) to process
# Generated from /scratch/smansour/scripts/bids/bids_gen_ids.py

STUDY="STUDY"
sublist=/KIMEL/tigrlab/projects/smansour/${STUDY}/sublist.txt

# Function for looping through subjects in sublist
index() {
   head -n $SLURM_ARRAY_TASK_ID $sublist \
   | tail -n 1
}

## build the mounts
subject=`index`
subject=${subject}'_ses-01'

inputfolder=/KIMEL/tigrlab/projects/smansour/${STUDY}/wma
outputfolder=/KIMEL/tigrlab/projects/smansour/${STUDY}/wma
export ATLASDIR=/KIMEL/tigrlab/scratch/smansour/org-atlas/ORG-Atlases-1.2/ORG-800FC-100HCP
inputfile=${inputfolder}/${subject}/${subject}_desc-preproc_tractography.vtk

echo $HOSTNAME

module load slicer/4.10.2
module load python/3.6.3-anaconda-5.0.1
module load whitematteranalysis/2020-04-24

export SLICER=/KIMEL/tigrlab/quarantine/slicer/4.10.2/build/Slicer
export SLICER_LIB=/KIMEL/tigrlab/quarantine/slicer/4.10.2/build/lib
export SLICER_CLI=/KIMEL/tigrlab/quarantine/slicer/4.10.2/build/lib/Slicer-4.10/cli-modules

echo $subject
#--------------------------------------------------------------------------------------------------------------------
echo "STEP 5 OF 9"
#--------------------------------------------------------------------------------------------------------------------

#transform fiber locations

if [ ! -f "${outputfolder}/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography/cluster_00800.vtp" ]; then
  echo wm_harden_transform.py \
    $outputfolder/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed \
    $outputfolder/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography \
    $SLICER \
    -i \
    -t $outputfolder/TractRegistration/${subject}_desc-preproc_tractography/output_tractography/itk_txform_${subject}_desc-preproc_tractography.tfm
  xvfb-run -a -s "-screen 0 640x480x24 +iglx" wm_harden_transform.py \
    $outputfolder/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed \
    $outputfolder/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography \
    $SLICER \
    -i \
    -t $outputfolder/TractRegistration/${subject}_desc-preproc_tractography/output_tractography/itk_txform_${subject}_desc-preproc_tractography.tfm
fi

#--------------------------------------------------------------------------------------------------------------------
echo "STEP 6 OF 9"
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${outputfolder}/FiberClustering/SeparatedClusters/${subject}/tracts_commissural/cluster_00800.vtp" ]; then
  echo wm_separate_clusters_by_hemisphere.py \
    $outputfolder/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography \
    $outputfolder/FiberClustering/SeparatedClusters/${subject}
  wm_separate_clusters_by_hemisphere.py \
    $outputfolder/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography \
    $outputfolder/FiberClustering/SeparatedClusters/${subject}
fi

#--------------------------------------------------------------------------------------------------------------------
echo "STEP 7 OF 9"
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${outputfolder}/AnatomicalTracts/${subject}/T_CPC.vtp" ]; then
  echo wm_append_clusters_to_anatomical_tracts.py \
    $outputfolder/FiberClustering/SeparatedClusters/${subject} \
    $ATLASDIR \
    $outputfolder/AnatomicalTracts/${subject}
  wm_append_clusters_to_anatomical_tracts.py \
    $outputfolder/FiberClustering/SeparatedClusters/${subject} \
    $ATLASDIR \
    $outputfolder/AnatomicalTracts/${subject}
fi

#--------------------------------------------------------------------------------------------------------------------
echo "STEP 8 OF 9"
#--------------------------------------------------------------------------------------------------------------------

#left
if [ ! -f "${outputfolder}/DiffusionMeasurements/${subject}_left_hemisphere_clusters.csv" ]; then
  echo wm_diffusion_measurements.py \
    $outputfolder/FiberClustering/SeparatedClusters/${subject}/tracts_left_hemisphere/ \
    $outputfolder/DiffusionMeasurements/${subject}_left_hemisphere_clusters.csv \
    $SLICER_CLI/FiberTractMeasurements
  wm_diffusion_measurements.py \
    $outputfolder/FiberClustering/SeparatedClusters/${subject}/tracts_left_hemisphere/ \
    $outputfolder/DiffusionMeasurements/${subject}_left_hemisphere_clusters.csv \
    $SLICER_CLI/FiberTractMeasurements
fi

#right
if [ ! -f "${outputfolder}/DiffusionMeasurements/${subject}_right_hemisphere_clusters.csv" ]; then
  wm_diffusion_measurements.py \
    $outputfolder/FiberClustering/SeparatedClusters/${subject}/tracts_right_hemisphere/ \
    $outputfolder/DiffusionMeasurements/${subject}_right_hemisphere_clusters.csv \
    $SLICER_CLI/FiberTractMeasurements
fi

#commissural
if [ ! -f "${outputfolder}/DiffusionMeasurements/${subject}_commissural_clusters.csv" ]; then
  wm_diffusion_measurements.py \
    $outputfolder/FiberClustering/SeparatedClusters/${subject}/tracts_commissural/ \
    $outputfolder/DiffusionMeasurements/${subject}_commissural_clusters.csv \
    $SLICER_CLI/FiberTractMeasurements
fi

#--------------------------------------------------------------------------------------------------------------------
echo "STEP 9 OF 9"
#--------------------------------------------------------------------------------------------------------------------

#anatomical tracts
if [ ! -f "${outputfolder}/DiffusionMeasurements/${subject}_anatomical_tracts.csv" ]; then
  echo wm_diffusion_measurements.py \
    $outputfolder/AnatomicalTracts/${subject} \
    $outputfolder/DiffusionMeasurements/${subject}_anatomical_tracts.csv \
    $SLICER_CLI/FiberTractMeasurements
  wm_diffusion_measurements.py \
    $outputfolder/AnatomicalTracts/${subject} \
    $outputfolder/DiffusionMeasurements/${subject}_anatomical_tracts.csv \
    $SLICER_CLI/FiberTractMeasurements
fi

echo "CLEANING UP"
echo "rm ${outputfolder}/FiberClustering/InitialClusters/${subject}_desc-preproc_tractography_reg/cluster*vtp"
#rm ${outputfolder}/FiberClustering/InitialClusters/${subject}_desc-preproc_tractography_reg/cluster*vtp
echo "rm ${outputfolder}/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed/cluster*vtp"
#rm ${outputfolder}/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed/cluster*vtp
echo "rm ${outputfolder}/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography/cluster*.vtp"
#rm ${outputfolder}/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography/cluster*.vtp
