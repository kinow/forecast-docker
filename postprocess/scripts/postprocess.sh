#!/bin/bash

#stop the script if we use an unset variable, or a command fails
set -o nounset -o errexit

# script to gather Ensemble and format to be readable by visualisation
# this script uses both CDO and NCO operators! Both these packages need
# to be installed on your machine.

# This script uses the uncertaintyTemplate from the UNCERTAINTY_TEMPLATE_NC_FILE file 
#   which contains one variable: template_group, with two attributes:
#     x ancillary_variables (will be set by this script)
#     x ref = "http://www.uncertml.org/statistics/statistics-collection"

# get forecast output files from the INPUT_TARBALL and put them into temp/
# these files should look like forecast/member??-discharge_dailyTot_output.nc
mkdir temp/
tar -xjf ${INPUT_TARBALL} -C temp/

# make a file with the ensemble mean.
cdo ensmean temp/forecast/member??-discharge_dailyTot_output.nc dischargeEnsMeanOut.nc 

# make a file with the ensemble standard deviation
cdo ensstd temp/forecast/member??-discharge_dailyTot_output.nc dischargeEnsStdOut.nc

#change the name of the standard deviation to discharge_error, save in a temp file
cdo setname,discharge_error dischargeEnsStdOut.nc dischargeEnsStdOutTemp.nc

# merge the mean and the std into a single .nc file
cdo merge dischargeEnsMeanOut.nc dischargeEnsStdOutTemp.nc dischargeEns.nc

# merge the uncertaintyTemplate into dischargeEns.nc. 
# this is done with NCO operator ncks because CDO has problems with merging
# empty (no data, only meta) files.
ncks -A $UNCERTAINTY_TEMPLATE_NC_FILE dischargeEns.nc

# add the "ref" attribute to the dischare_error and the discharge variables
ncatted -a ref,discharge_error,o,c,http://www.uncertml.org/statistics/standard-deviation -a ref,discharge,o,c,http://www.uncertml.org/statistics/mean dischargeEns.nc

# rename the template_group variable to discharge_group
ncrename -v template_group,discharge_group dischargeEns.nc

# set the ancillary_variables attribute of the discharge group. In this way,
# we indicate that the discharge and the discharge_uncertaunty form a group.
ncatted -a ancillary_variables,discharge_group,o,c,"discharge discharge_error" dischargeEns.nc

# make the output tarball (with just one file, but for consistency)
tar cjf ${OUTPUT_TARBALL_NAME}.tar.bz2 dischargeEns.nc
