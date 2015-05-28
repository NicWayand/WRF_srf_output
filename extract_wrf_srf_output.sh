#!/bin/bash

# This script takes a list of WRF indices (from get_indices_from_Lat_Lon.py) and extracts point ascii files containing
# multiple user defined variables

# Load in your personal PBS settings (if needed)  and required modules (netcdf)
# i.e. 
# module load netcdf_4.3.2-icc_14.0.3
# module load epel_packages
./Nics_PBS_settings

#### EDIT HERE! ####
maindir="/gscratch/snow/nicway/WRF/"
datadir=$maindir"d4/" # Where your WRF files are
BASIN="SNQ_pt" # Name of your WRF indices file created by get_indices_from_Lat_Lon.py

# Grab all files
FL=$datadir"/wrfout*" # --ignore='*f24*' # option to ignore certain hours if needed
# Define path to file list
I_lat_lon_list=$maindir"Basin_pts/"$BASIN"/"$BASIN".txt"

# Clear all temp and output files (if script has been run before)
while read FN Ilat Ilon cLat cLon tlat tlon
do
        outpdir=$maindir"Basin_pts/"$BASIN"/"$FN"/"
        mkdir -p $outpdir
	cd $outpdir 
	rm -f time ppt temp q press sw lw u10 v10
done < $I_lat_lon_list
echo Done Clearing up previous files

# Now loop through each WRF file
# NOTE: You may have to edit below depending on your netcdf variable names and date format
#
for cf in $FL
do
	echo $cf
	# Loop through each user defined WRF grid cell/point we want, extract time series for given WRF file
	# to the ascii file
	while read FN Ilat Ilon cLat cLon tlat tlon
	do

		#echo $Ilat $Ilon $cLat $cLon $tlat $tlon
		tempdir=$maindir"Basin_pts/"$BASIN"/"$FN"/TEMP/"
		mkdir -p $tempdir

		outpdir=$maindir"Basin_pts/"$BASIN"/"$FN"/"

		ncdump -t -v Times $cf | sed -e '1,/data:/d' -e '$d' | tail -1 > $tempdir"temp1"
		#sed 's/Times = //g' $tempdir"temp1" > $tempdir"temp2"
		sed 's/"//g'       $tempdir"temp1" > $tempdir"temp2"
		#sed 's$, $\n$g'    $tempdir"temp3" > $tempdir"temp4" 
		#sed '/^$/d'        $tempdir"temp4" > $tempdir"temp5" 	
		#sed 's/    //g'    $tempdir"temp5" > $tempdir"temp6"
		sed 's/;//g'       $tempdir"temp2" > $tempdir"time"
	
		ncks -s '%13.9f\n' -C -H -d south_north,$Ilat,$Ilat -d west_east,$Ilon,$Ilon -v RAINNC $cf > $tempdir"ppt"
		ncks -s '%13.3f\n' -C -H -d south_north,$Ilat,$Ilat -d west_east,$Ilon,$Ilon -v T2 $cf > $tempdir"temp"
		ncks -s '%13.9f\n' -C -H -d south_north,$Ilat,$Ilat -d west_east,$Ilon,$Ilon -v Q2 $cf > $tempdir"q"
		ncks -s '%13.9f\n' -C -H -d south_north,$Ilat,$Ilat -d west_east,$Ilon,$Ilon -v PSFC $cf > $tempdir"press"
		ncks -s '%13.3f\n' -C -H -d south_north,$Ilat,$Ilat -d west_east,$Ilon,$Ilon -v SWDOWN $cf > $tempdir"sw"
		ncks -s '%13.3f\n' -C -H -d south_north,$Ilat,$Ilat -d west_east,$Ilon,$Ilon -v GLW $cf > $tempdir"lw"
		ncks -s '%13.3f\n' -C -H -d south_north,$Ilat,$Ilat -d west_east,$Ilon,$Ilon -v U10 $cf > $tempdir"u10"
                ncks -s '%13.3f\n' -C -H -d south_north,$Ilat,$Ilat -d west_east,$Ilon,$Ilon -v V10 $cf > $tempdir"v10"

		cat $tempdir"time" >> $outpdir"time"
		head -n -2 $tempdir"ppt" >> $outpdir"ppt"
		head -n -2 $tempdir"temp" >> $outpdir"temp"
		head -n -2 $tempdir"q" >> $outpdir"q"
		head -n -2 $tempdir"press" >> $outpdir"press"
		head -n -2 $tempdir"sw" >> $outpdir"sw"
		head -n -2 $tempdir"lw" >> $outpdir"lw"
		head -n -2 $tempdir"v10" >> $outpdir"v10"
		head -n -2 $tempdir"u10" >> $outpdir"u10"
		

	done < $I_lat_lon_list
done

# Merge files together (We have created indiviudal files for Air temp, RH etc, now merge to one file)
while read FN Ilat Ilon cLat cLon tlat tlon
do
	findir=$maindir"Basin_pts/"$BASIN"/"$FN"/OUT/"
	comdir=$maindir"Basin_pts/"$BASIN"/ALL/"
	mkdir -p $findir
	mkdir -p $comdir

	outpdir=$maindir"Basin_pts/"$BASIN"/"$FN"/"	
	cd $outpdir

	paste time temp ppt q press u10 v10  sw lw > $findir"forcing_"$FN".txt"
	cp $findir"forcing_"$FN".txt" $comdir"forcing_"$FN".txt"
	cp $outpdir"time" $comdir"time_"$FN".txt"

	#paste time > $findir"forcing_"$FN".txt"

done < $I_lat_lon_list

