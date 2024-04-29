#!/bin/bash -l

#SBATCH --array=1-83
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=12000
#SBATCH --cpus-per-task=1
#SBATCH --time=8:00:00
#SBATCH --export=ALL
#SBATCH --job-name wma
#SBATCH --output=wma_%j.txt

cd $SLURM_SUBMIT_DIR

STUDY="STUDY"
sublist=/KIMEL/tigrlab/projects/smansour/${STUDY}/sublist_rerun.txt

# Function for looping through subjects in sublist
index() {
   head -n $SLURM_ARRAY_TASK_ID $sublist \
   | tail -n 1
}

## build the mounts
subject=`index`
inputfolder=/KIMEL/tigrlab/projects/smansour/${STUDY}/wma/Tracts
outputfolder=/KIMEL/tigrlab/projects/smansour/${STUDY}/wma
export ATLASDIR=/KIMEL/tigrlab/scratch/smansour/org-atlas/ORG-Atlases-1.2/ORG-800FC-100HCP
inputfile=${inputfolder}/${subject}/${subject}_desc-preproc_tractography.vtk

echo $HOSTNAME

source /KIMEL/tigrlab/quarantine/kimel_modules.sh
module load slicer/4.10.2
module load python/3.6.3-anaconda-5.0.1
module load whitematteranalysis/2020-04-24

export SLICER=/KIMEL/tigrlab/quarantine/slicer/4.10.2/build/Slicer
export SLICER_LIB=/KIMEL/tigrlab/quarantine/slicer/4.10.2/build/lib
export SLICER_CLI=/KIMEL/tigrlab/quarantine/slicer/4.10.2/build/lib/Slicer-4.10/cli-modules

echo $subject

#--------------------------------------------------------------------------------------------------------------------
echo "STEP 1 OF 9"
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${outputfolder}/TractRegistration/${subject}_desc-preproc_tractography/output_tractography/${subject}_desc-preproc_tractography_reg.vtk" ]; then
  echo wm_register_to_atlas_new.py \
    -mode rigid_affine_fast \
    $inputfile \
    $ATLASDIR/atlas.vtp \
    $outputfolder/TractRegistration
  wm_register_to_atlas_new.py \
    -mode rigid_affine_fast \
    $inputfile \
    $ATLASDIR/atlas.vtp \
    $outputfolder/TractRegistration
fi

#--------------------------------------------------------------------------------------------------------------------
echo "STEP 2 OF 9"
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${outputfolder}/FiberClustering/InitialClusters/${subject}_desc-preproc_tractography_reg/cluster_00800.vtp" ]; then
  echo wm_cluster_from_atlas.py \
    -norender \
    $outputfolder/TractRegistration/${subject}_desc-preproc_tractography/output_tractography/${subject}_desc-preproc_tractography_reg.vtk \
    $ATLASDIR \
    $outputfolder/FiberClustering/InitialClusters
  wm_cluster_from_atlas.py \
    -norender \
    $outputfolder/TractRegistration/${subject}_desc-preproc_tractography/output_tractography/${subject}_desc-preproc_tractography_reg.vtk \
    $ATLASDIR \
    $outputfolder/FiberClustering/InitialClusters
fi

#--------------------------------------------------------------------------------------------------------------------
echo "STEP 3 OF 9"
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${outputfolder}/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed/cluster_00800.vtp" ]; then
  echo wm_cluster_remove_outliers.py \
    -cluster_outlier_std 4 \
    $outputfolder/FiberClustering/InitialClusters/${subject}_desc-preproc_tractography_reg \
    $ATLASDIR \
    $outputfolder/FiberClustering/OutlierRemovedClusters
  wm_cluster_remove_outliers.py \
    -cluster_outlier_std 4 \
    $outputfolder/FiberClustering/InitialClusters/${subject}_desc-preproc_tractography_reg \
    $ATLASDIR \
    $outputfolder/FiberClustering/OutlierRemovedClusters
fi

#--------------------------------------------------------------------------------------------------------------------
echo "STEP 4 OF 9"
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${outputfolder}/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed/cluster_location_by_hemisphere.log" ]; then
  echo wm_assess_cluster_location_by_hemisphere.py \
    $outputfolder/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed \
    -clusterLocationFile $ATLASDIR/cluster_hemisphere_location.txt
  wm_assess_cluster_location_by_hemisphere.py \
    $outputfolder/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed \
    -clusterLocationFile $ATLASDIR/cluster_hemisphere_location.txt
fi


echo "CLEANING UP"
echo "rm ${outputfolder}/FiberClustering/InitialClusters/${subject}_desc-preproc_tractography_reg/cluster*vtp"
#rm ${outputfolder}/FiberClustering/InitialClusters/${subject}_desc-preproc_tractography_reg/cluster*vtp
