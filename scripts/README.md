# UKF Tractography and White Matter Analysis

<p float="left">
  <img src="https://user-images.githubusercontent.com/54225067/112897813-1373d680-90ae-11eb-8254-044c38df1594.png"/> 
</p>

### About

In the lab, there has been a growing interest in the new diffusion tractography method we call **Slicer Tractography**. This method is based on generating tracts recursively using a [two-tensor model](https://doi.org/10.1007/978-3-642-04268-3_110) and clustering the tracts using the [ORG atlas](https://doi.org/10.1016/j.neuroimage.2018.06.027).

The purpose of this repo is to help anyone get started with running this pipeline locally or on [SciNet](https://docs.scinet.utoronto.ca/index.php/Main_Page) using Singularity containers. 

If you are working with a bunch of high quality data, you may have to run this pipeline on SciNet. Tractography generation is very resource-intensive, so you may experience memory issues when running it locally/submitting it to our nodes. Luckily, SciNet helps with this by just giving us enough power to generate what we need. If you are just getting started with SciNet, you can find out how to sign up on [our wiki](https://github.com/TIGRLab/admin/wiki/SciNet) and get a basic start for submitting jobs on [theirs](https://docs.scinet.utoronto.ca/index.php/Niagara_Quickstart).

## Requirements

For this pipeline, you'll just need preprocessed diffusion outputs. You can use `qsiprep` or `dmriprep` outputs. You can find out more on how to do that [here](http://imaging-genetics.camh.ca/documentation/#/methods/QSIprep_based_DWI_processing).

## Running UKFTractography

Submit this script to SciNet.

`sbatch ./00_ukf_scinet.sh`

## Running White Matter Analysis

### Step 1 (SCC)

Submit this script to the SCC cluster.

`sbatch ./01_wma_scc.sh`

### Step 2 (Kimel)

Submit this script to the local kimel cluster.

`sbatch ./02_wma_kimel.sh`

### Step 3 (Local, in terminal)

Run the steps here locally on your computer.

`./03_wma_qc.sh`
