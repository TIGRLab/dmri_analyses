dwi_directory=$1
data_directory=$2

mkdir -p "${data_directory}/response_functions" "${data_directory}/07_upsampled" "${data_directory}/08_masks" "${data_directory}/09_extracted" "${data_directory}/09_fod"
mkdir -p "${data_directory}/template/fod_input" "${data_directory}/template/mask_input" "${data_directory}/11_register" "${data_directory}/12_template_mask"
mkdir -p "${data_directory}/14_warp" "${data_directory}/15_segment" "${data_directory}/16_reorient"

for site in "CMH" "UHN" "UBC"; do
site_name = $site
dwi_directory="/projects/smansour/CARTBIND2020/${site}/dmriprep_rename/dmripreproc"
for sub_path in $dwi_directory/sub-0*; do
    sub=$(basename "$sub_path")
    subid="${sub#sub-}"
    if [ site = 'UBC' ]
    then
        subid="0${subid}"
        echo $subid
    fi
    for ses_path in $sub_path/ses-01*; do
        ses=$(basename "$ses_path")
        dwi_base_path=$dwi_directory/${sub}/${ses}/dwi
        # eddy_base="${base_path}/eddy_corrected"
        dwi_base="$dwi_base_path/${sub}_${ses}"

        # sub_base="$base_path/${sub}/${ses}/dwi/${sub}_${ses}"
        # sub_base_file="${sub}_${ses}"
        sub_base_file="CBN02_UHN_${subid}"
        #mask="/projects/smansour/CARTBIND2020/CMH/FBA/masks/"$sub"_"$ses"_fod_mask.nii.gz"

        # Fixel-based analysis steps
        # Step 6: Computing an (average) white matter response function
        dwi2response tournier "${dwi_base}_desc-preproc_dwi.nii.gz" -fslgrad "${dwi_base}_desc-preproc_dwi.bvec" "${dwi_base}_desc-preproc_dwi.bval" "${data_directory}/response_functions/${sub_base_file}_response.txt"
        
    done
done
done

# RUN ONCE
responsemean ${data_directory}/response_functions/sub-* "${data_directory}/group_average_response.txt"

for sub_path in $dwi_directory/sub-0*; do
    sub=$(basename "$sub_path")
    for ses_path in $sub_path/ses-01*; do
        ses=$(basename "$ses_path")
        dwi_base_path=$dwi_directory/${sub}/${ses}/dwi
        # eddy_base="${base_path}/eddy_corrected"
        dwi_base="$dwi_base_path/${sub}_${ses}"

        # sub_base="$base_path/${sub}/${ses}/dwi/${sub}_${ses}"
        # sub_base_file="${sub}_${ses}"
        sub_base_file="CBN02_UHN_${sub}"
        
        # Step 7: Upsampling DW images
        mrgrid "${dwi_base}_desc-preproc_dwi.nii.gz" regrid -vox 1.25 "${data_directory}/07_upsampled/${sub_base_file}_upsampled.nii.gz"

        # Step 8: Compute upsampled brain mask images
        dwi2mask "${dwi_base}_desc-preproc_dwi.nii.gz" -fslgrad "${dwi_base}_desc-preproc_dwi.bvec" "${dwi_base}_desc-preproc_dwi.bval" "${data_directory}/08_masks/${sub_base_file}_mask.nii.gz"

        # Step 9: Fibre Orientation Distribution estimation (spherical deconvolution)
        dwiextract "${dwi_base}_desc-preproc_dwi.nii.gz"  -fslgrad "${dwi_base}_desc-preproc_dwi.bvec" "${dwi_base}_desc-preproc_dwi.bval" -export_grad_fsl "${data_directory}/09_extracted/${sub_base_file}_dwiextract.bvec" "${data_directory}/09_extracted/${sub_base_file}_dwiextract.bval" "${data_directory}/09_extracted/${sub_base_file}_dwiextract.nii.gz"
        dwi2fod msmt_csd "${data_directory}/09_extracted/${sub_base_file}_dwiextract.nii.gz" "${data_directory}/group_average_response.txt" "${data_directory}/09_fod/${sub_base_file}_fod.nii.gz" -fslgrad "${data_directory}/09_extracted/${sub_base_file}_dwiextract.bvec" "${data_directory}/09_extracted/${sub_base_file}_dwiextract.bval"  -mask "${data_directory}/08_masks/${sub_base_file}_mask.nii.gz"
        # # (based on)
        # dwiextract "${data_directory}/07_upsampled/${sub_base_file}_upsampled.nii.gz" - | dwi2fod msmt_csd - "${data_directory}/group_average_response.txt" "${data_directory}/09_fod/${sub_base_file}_fod.nii.gz" -mask "${data_directory}/08_masks/${sub_base_file}_upsampled_mask.nii.gz"

        # Step 10: Generate a study-specific unbiased FOD template
        ln -sr "${data_directory}/09_fod/${sub_base_file}_fod.nii.gz" "${data_directory}/template/fod_input/${sub_base_file}_PRE.nii.gz"
        ln -sr "${data_directory}/08_masks/${sub_base_file}_mask.nii.gz" "${data_directory}/template/mask_input/${sub_base_file}_PRE.nii.gz"
        cp "${data_directory}/09_fod/${sub_base_file}_fod.nii.gz" "${data_directory}/template/fod_input/${sub_base_file}_PRE.nii.gz"
        cp "${data_directory}/08_masks/${sub_base_file}_mask.nii.gz" "${data_directory}/template/mask_input/${sub_base_file}_PRE.nii.gz"

    done
done

# RUN ONCE
population_template "${data_directory}/template/fod_input" -mask_dir "${data_directory}/template/mask_input" "${data_directory}/template/wmfod_template.nii.gz"

for sub_path in $dwi_directory/sub-0*; do
    sub=$(basename "$sub_path")
    for ses_path in $sub_path/ses-01*; do
        ses=$(basename "$ses_path")
        dwi_base_path=$dwi_directory/${sub}/${ses}/dwi
        # eddy_base="${base_path}/eddy_corrected"
        dwi_base="$dwi_base_path/${sub}_${ses}"

        # sub_base="$base_path/${sub}/${ses}/dwi/${sub}_${ses}"
        # sub_base_file="${sub}_${ses}"
        sub_base_file="CBN02_UHN_${sub}"
        
        # Step 11: Register all subject FOD images to the FOD template
        mrregister "${data_directory}/09_fod/${sub_base_file}_fod.nii.gz" -mask1 "${data_directory}/08_masks/${sub_base_file}_mask.nii.gz" "${data_directory}/template/wmfod_template.nii.gz" -nl_warp "${data_directory}/11_register/${sub_base_file}_subject2template_warp.nii.gz" "${data_directory}/11_register/${sub_base_file}_template2subject_warp.nii.gz"
        
        # Step 12: Compute the template mask (intersection of all subject masks in template space)
        mrtransform "${data_directory}/08_masks/${sub_base_file}_mask.nii.gz" -warp "${data_directory}/11_register/${sub_base_file}_subject2template_warp.nii.gz" -interp nearest -datatype bit "${data_directory}/12_template_mask/${sub_base_file}_dwi_mask_in_template_space.nii.gz"
        
    done
done
       
# RUN ONCE
mrmath ${data_directory}/12_template_mask/*dwi_mask_in_template_space.nii.gz min "${data_directory}/template/template_mask.nii.gz" -datatype bit

# Step 13: Compute a white matter template analysis fixel mask
# RUN ONCE
fod2fixel -mask "${data_directory}/template/template_mask.nii.gz" -fmls_peak_value 0.10 "${data_directory}/template/wmfod_template.nii.gz" "${data_directory}/template/fixel_mask"

for sub_path in $dwi_directory/sub-0*; do
    sub=$(basename "$sub_path")
    for ses_path in $sub_path/ses-01*; do
        ses=$(basename "$ses_path")
        dwi_base_path=$dwi_directory/${sub}/${ses}/dwi
        # eddy_base="${base_path}/eddy_corrected"
        dwi_base="$dwi_base_path/${sub}_${ses}"

        # sub_base="$base_path/${sub}/${ses}/dwi/${sub}_${ses}"
        # sub_base_file="${sub}_${ses}"
        sub_base_file="CBN02_UHN_${sub}"
        
        # Step 14: Warp FOD images to template space
        mrtransform "${data_directory}/09_fod/${sub_base_file}_fod.nii.gz" -warp "${data_directory}/11_register/${sub_base_file}_subject2template_warp.nii.gz" -reorient_fod no "${data_directory}/14_warp/${sub_base_file}_fod_in_template_space_NOT_REORIENTED.nii.gz"

        # Step 15: Segment FOD images to estimate fixels and their apparent fibre density (FD)
        fod2fixel -mask "${data_directory}/template/template_mask.nii.gz" "${data_directory}/14_warp/${sub_base_file}_fod_in_template_space_NOT_REORIENTED.nii.gz" "${data_directory}/15_segment/${sub_base_file}_fixel_in_template_space_NOT_REORIENTED" -afd "fd.nii.gz"

        # Step 16: Reorient fixels
        fixelreorient "${data_directory}/15_segment/${sub_base_file}_fixel_in_template_space_NOT_REORIENTED" "${data_directory}/11_register/${sub_base_file}_subject2template_warp.nii.gz" "${data_directory}/16_reorient/${sub_base_file}_fixel_in_template_space"

        # Step 17: Assign subject fixels to template fixels
        fixelcorrespondence "${data_directory}/16_reorient/${sub_base_file}_fixel_in_template_space/fd.nii.gz" "${data_directory}/template/fixel_mask" "${data_directory}/template/fd" "${sub_base_file}_PRE.nii.gz"
        
        # Step 18: Compute the fibre cross-section (FC) metric
        warp2metric "${data_directory}/11_register/${sub_base_file}_subject2template_warp.nii.gz" -fc "${data_directory}/template/fixel_mask" "${data_directory}/template/fc" "${sub_base_file}_IN.nii.gz"

    done
done

# Step 19: Compute a combined measure of fibre density and cross-section (FDC)
# RUN ONCE
mkdir "${data_directory}/template/fdc/"
cp "${data_directory}/template/fc/index.mif" "${data_directory}/template/fdc/"
cp "${data_directory}/template/fc/directions.mif" "${data_directory}/template/fdc/"

for sub_path in $dwi_directory/sub-0*; do
    sub=$(basename "$sub_path")
    for ses_path in $sub_path/ses-01*; do
        ses=$(basename "$ses_path")
        dwi_base_path=$dwi_directory/${sub}/${ses}/dwi
        # eddy_base="${base_path}/eddy_corrected"
        dwi_base="$dwi_base_path/${sub}_${ses}"

        # sub_base="$base_path/${sub}/${ses}/dwi/${sub}_${ses}"
        # sub_base_file="${sub}_${ses}"
        sub_base_file="CBN02_UHN_${sub}"

        mrcalc "${data_directory}/template/fd/${sub_base_file}_PRE.nii.gz" "${data_directory}/template/fc/${sub_base_file}_IN.nii.gz" -mult "${data_directory}/template/fdc/${sub_base_file}_IN.nii.gz"
        
    done
done

# Step 20: Perform whole-brain fibre tractography on the FOD template
# RUN REST OF CODE ONCE
tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 "${data_directory}/template/wmfod_template.nii.gz" -seed_image "${data_directory}/template/template_mask.nii.gz" -mask "${data_directory}/template/template_mask.nii.gz" -select 20000000 -cutoff 0.10 "${data_directory}/template/tracks_20_million.tck"

# Step 21: Reduce biases in tractogram densities
tcksift "${data_directory}/template/tracks_20_million.tck" "${data_directory}/template/wmfod_template.nii.gz" "${data_directory}/template/tracks_20_million_sift.tck" -term_number 2000000

# Step 22: Generate fixel-fixel connectivity matrix
mkdir ${data_directory}/22_matrix
fixelconnectivity ${data_directory}/template/fixel_mask "${data_directory}/template/tracks_20_million_sift.tck" ${data_directory}/22_matrix

# Step 23: Smooth fixel data using fixel-fixel connectivity
fixelfilter ${data_directory}/template/fd smooth ${data_directory}/fd_smooth -matrix ${data_directory}/22_matrix
# fixelfilter ${data_directory}/template/log_fc smooth ${data_directory}/log_fc_smooth -matrix ${data_directory}/22_matrix
fixelfilter ${data_directory}/template/fdc smooth ${data_directory}/fdc_smooth -matrix ${data_directory}/22_matrix

# Step 24: Perform statistical analysis of FD, FC, and FDC
filelist="/data_directory/csv/sublist_min.txt"
filelist_pre="/data_directory/csv/sublist_pre.txt"
contrast="/data_directory/csv/CART_contrast.txt"
design="/data_directory/csv/CART_DesMat_min.csv"

filelist_pre="${data_directory}/csv/baseline_sublist_PRE_min.txt"
contrast="${data_directory}/csv/baseline_con_CMH.csv"
design="${data_directory}/csv/baseline_desmat_CMH_min.csv"
fixelcfestats ${data_directory}/fd_smooth/ $filelist_pre $design $contrast ${data_directory}/22_matrix/ ${data_directory}/stats_fd/