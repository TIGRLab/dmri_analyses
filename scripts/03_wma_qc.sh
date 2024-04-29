STUDY="STUDY"
sublist=/KIMEL/tigrlab/projects/smansour/${STUDY}/sublist.txt

inputfolder=/KIMEL/tigrlab/projects/smansour/${STUDY}/wma/Tracts
outputfolder=/KIMEL/tigrlab/projects/smansour/${STUDY}/wma
export ATLASDIR=/KIMEL/tigrlab/scratch/smansour/org-atlas/ORG-Atlases-1.2/ORG-800FC-100HCP

sing_img=/archive/code/containers/WHITEMATTERANALYSIS/tigrlab_whitematteranalysis_latest-2022-03-23-a40a672d33ef.simg

for sub_path in /KIMEL/tigrlab/projects/smansour/${STUDY}/wma/Tracts/sub-*; do
        subject="$(basename -- $sub_path)"
        echo $subject

        if [ -d $outputfolder/AnatomicalTracts/${subject} ]; then
                # AnatomicalTracts
                sub_anat=$outputfolder/AnatomicalTracts/${subject}
                sub_qc=$outputfolder/QC/AnatomicalTracts/${subject}
                echo wm_quality_control_tractography.py $sub_anat $sub_qc
                # xvfb-run -a -s "-screen 0 640x480x24 +iglx" wm_quality_control_tractography.py $sub_anat $sub_qc
                echo singularity exec -B $outputfolder ${sing_img} wm_quality_control_tractography.py $sub_anat $sub_qc
                singularity exec -B $outputfolder ${sing_img} wm_quality_control_tractography.py $sub_anat $sub_qc
        
                # Registration
                sub_tract=$outputfolder/TractRegistration/${subject}_desc-preproc_tractography/output_tractography/${subject}_desc-preproc_tractography_reg.vtk
                sub_reg=$outputfolder/QC/RegTractOverlap/${subject}
                echo wm_quality_control_tract_overlap.py $ATLASDIR/atlas.vtp $sub_tract $sub_reg
                # xvfb-run -a -s "-screen 0 640x480x24 +iglx" wm_quality_control_tract_overlap.py $ATLASDIR/atlas.vtp $sub_tract $sub_reg
                echo singularity exec -B  $ATLASDIR/atlas.vtp -B $outputfolder ${sing_img} wm_quality_control_tract_overlap.py $ATLASDIR/atlas.vtp $sub_tract $sub_reg
                singularity exec -B  $ATLASDIR/atlas.vtp -B $outputfolder ${sing_img} wm_quality_control_tract_overlap.py $ATLASDIR/atlas.vtp $sub_tract $sub_reg
        
                # Input
                sub_vtk_tract=$inputfolder/${subject}	
                sub_tract_qc=$outputfolder/QC/InputTractography
                echo wm_quality_control_tractography.py $sub_vtk_tract $sub_tract_qc
                # xvfb-run -a -s "-screen 0 640x480x24 +iglx" wm_quality_control_tractography.py $sub_vtk_tract $sub_tract_qc
                echo singularity exec -B $inputfolder -B $outputfolder ${sing_img} wm_quality_control_tractography.py $sub_vtk_tract $sub_tract_qc
                singularity exec -B $inputfolder -B $outputfolder ${sing_img} wm_quality_control_tractography.py $sub_vtk_tract $sub_tract_qc
        fi
done