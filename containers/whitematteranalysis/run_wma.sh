#!/bin/bash

tractfolder=$1
subject=$2

#define environment variables
vtk_file=${tractfolder}/Tracts/${subject}/${subject}_desc-preproc_tractography.vtk

#--------------------------------------------------------------------------------------------------------------------
#STEP 1 OF 9
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${tractfolder}/TractRegistration/${subject}_desc-preproc_tractography/output_tractography/${subject}_desc-preproc_tractography_reg.vtk" ]; then
  wm_register_to_atlas_new.py \
    -mode rigid_affine_fast \
    $vtk_file \
    $ATLASDIR/atlas.vtp \
    $tractfolder/TractRegistration
fi

#--------------------------------------------------------------------------------------------------------------------
#STEP 2 OF 9
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${tractfolder}/FiberClustering/InitialClusters/${subject}_desc-preproc_tractography_reg/cluster_00800.vtp" ]; then
  xvfb-run -a -s "-screen 0 640x480x24 +iglx" wm_cluster_from_atlas.py \
    -j 4 \
    $tractfolder/TractRegistration/${subject}_desc-preproc_tractography/output_tractography/${subject}_desc-preproc_tractography_reg.vtk \
    $ATLASDIR \
    $tractfolder/FiberClustering/InitialClusters
fi

#--------------------------------------------------------------------------------------------------------------------
#STEP 3 OF 9
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${tractfolder}/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed/cluster_00800.vtp" ]; then
  wm_cluster_remove_outliers.py \
    -cluster_outlier_std 4 \
    $tractfolder/FiberClustering/InitialClusters/${subject}_desc-preproc_tractography_reg \
    $ATLASDIR \
    $tractfolder/FiberClustering/OutlierRemovedClusters
fi

#--------------------------------------------------------------------------------------------------------------------
#STEP 4 OF 9
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${tractfolder}/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed/cluster_location_by_hemisphere.log" ]; then
  wm_assess_cluster_location_by_hemisphere.py \
    $tractfolder/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed \
    -clusterLocationFile $ATLASDIR/cluster_hemisphere_location.txt
fi

#--------------------------------------------------------------------------------------------------------------------
#STEP 5 OF 9
#--------------------------------------------------------------------------------------------------------------------

#transform fiber locations

if [ ! -f "${tractfolder}/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography/cluster_00800.vtp" ]; then
  xvfb-run -a -s "-screen 0 640x480x24 +iglx" wm_harden_transform.py \
    $tractfolder/FiberClustering/OutlierRemovedClusters/${subject}_desc-preproc_tractography_reg_outlier_removed \
    $tractfolder/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography \
    $SLICER \
    -i \
    -t $tractfolder/TractRegistration/${subject}_desc-preproc_tractography/output_tractography/itk_txform_${subject}_desc-preproc_tractography.tfm
fi

#--------------------------------------------------------------------------------------------------------------------
#STEP 6 OF 9
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${tractfolder}/FiberClustering/SeparatedClusters/${subject}/tracts_commissural/cluster_00800.vtp" ]; then
  wm_separate_clusters_by_hemisphere.py \
    $tractfolder/FiberClustering/TransformedClusters/${subject}_desc-preproc_tractography \
    $tractfolder/FiberClustering/SeparatedClusters/${subject}
fi

#--------------------------------------------------------------------------------------------------------------------
#STEP 7 OF 9
#--------------------------------------------------------------------------------------------------------------------

if [ ! -f "${tractfolder}/AnatomicalTracts/${subject}/T_CPC.vtp" ]; then
  wm_append_clusters_to_anatomical_tracts.py \
    $tractfolder/FiberClustering/SeparatedClusters/${subject} \
    $ATLASDIR \
    $tractfolder/AnatomicalTracts/${subject}
fi

#--------------------------------------------------------------------------------------------------------------------
#STEP 8 OF 9
#--------------------------------------------------------------------------------------------------------------------

#left
if [ ! -f "${tractfolder}/DiffusionMeasurements/${subject}_left_hemisphere_clusters.csv" ]; then
  wm_diffusion_measurements.py \
    $tractfolder/FiberClustering/SeparatedClusters/${subject}/tracts_left_hemisphere/ \
    $tractfolder/DiffusionMeasurements/${subject}_left_hemisphere_clusters.csv \
    $SLICER_CLI/FiberTractMeasurements
fi

#right
if [ ! -f "${tractfolder}/DiffusionMeasurements/${subject}_right_hemisphere_clusters.csv" ]; then
  wm_diffusion_measurements.py \
    $tractfolder/FiberClustering/SeparatedClusters/${subject}/tracts_right_hemisphere/ \
    $tractfolder/DiffusionMeasurements/${subject}_right_hemisphere_clusters.csv \
    $SLICER_CLI/FiberTractMeasurements
fi

#commissural
if [ ! -f "${tractfolder}/DiffusionMeasurements/${subject}_commissural_clusters.csv" ]; then
  wm_diffusion_measurements.py \
    $tractfolder/FiberClustering/SeparatedClusters/${subject}/tracts_commissural/ \
    $tractfolder/DiffusionMeasurements/${subject}_commissural_clusters.csv \
    $SLICER_CLI/FiberTractMeasurements
fi

#--------------------------------------------------------------------------------------------------------------------
#STEP 9 OF 9
#--------------------------------------------------------------------------------------------------------------------

#anatomical tracts
if [ ! -f "${tractfolder}/DiffusionMeasurements/${subject}_anatomical_tracts.csv" ]; then
  wm_diffusion_measurements.py \
    $tractfolder/AnatomicalTracts/${subject} \
    $tractfolder/DiffusionMeasurements/${subject}_anatomical_tracts.csv \
    $SLICER_CLI/FiberTractMeasurements
fi