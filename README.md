# pspdata
This repository contains all of the most important IDL software and data products
that were needed for McGinnis et al 2019. 

The directory /pro contains all of the major IDL procedures that were written and 
(hopefully all of) their dependent procedures. Most data products were stored in .FITS
files, and it is assumed the user has downloaded and included in the IDL_PATH the 
IDLASTRO repository (which is available at https://idlastro.gsfc.nasa.gov/). Programs 
from this repository were mainly used for the creation, modification, and reading of 
FITS files and as such, MRDFITS, SXPAR, and MWRFITS are used extensively, along with 
various other programs from IDLASTRO.
Other procedures that are needed, but were not written by me, are included in the 
/other directory. I have tried to make sure to include everything that is needed to
replicate the data, but it is possible that something has been overlooked. If that is
the case, please contact me at the email address below and I will include it.

The program PSP_MAKEDATA is intended to show how all of the data for this project
was generated. It is written so that it could theoretically be run with a single command
to autonomously generate everything from beginning to end, however, this would be a very
long process (on the order of 10^1 hours) and it would be better to run piecewise. I
have tried to make sure that everything in this script should work to reproduce the 
results in the /results directory, but if there are any snags, please let me know. 

The /results directory contains all of the files that are produced by PSP_MAKEDATA, and
then some extras. For each spacecraft potential/Bfield model combination, there is a 
directory containing the particle tracing results (in /data) and QA images in /pix.
The images in /pix were created with a procedure that is not included in this 
repository, but show the unwarped and warped pixels (pixels before and after tracing).
A few other QA plots are contained in each and show the post interpolation mask created
by PSP_CORR (the v*_corr*.png files), the creation of the synthetic measurement set 
(similar to Figure 1 in the paper - the v*_distr_span*.png files), and the process of
interpolation (the v*_interp*.png and v*_interpn*.png files for correction-applied and
no-correction-applied, respectively) and reinterpolation (the 
v*_interp_reinterp_k30.png and v*_interpn_reinterp_k30.png for correction and 
no-correction applied respectively). 


Please direct any questions or comments to:
Daniel McGinnis
daniel-mcginnis@uiowa.edu
