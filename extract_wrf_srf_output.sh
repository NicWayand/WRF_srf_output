#!/bin/bash

# Load netcdf module in hyak
module load netcdf_4.3.2-icc_14.0.3
module load epel_packages

# Script extracts one grid cell at a time by looping through a list of  

maindir="/gscratch/snow/nicway/WRF/"
datadir=$maindir"d4/"
BASIN=$1

#Lat lon indices (zero based)
#Ilat=113
#Ilon=34

FL=$datadir"/wrfout*" # --ignore='*f24*'
#FL=$datadir"MAURER12K_Forcing.1992-10.nc"
I_lat_lon_list=$maindir"Basin_pts/"$BASIN"/"$BASIN".txt"
#echo $I_lat_lon_list
#echo $FL

# Clear all temp and output files
while read FN Ilat Ilon cLat cLon tlat tlon
do
        outpdir=$maindir"Basin_pts/"$BASIN"/"$FN"/"
        mkdir -p $outpdir
	cd $outpdir 
	rm -f time ppt temp q press sw lw u10 v10
        #rm -rv TEMP
        #rm -rv OUT
done < $I_lat_lon_list
echo Done Clearing up previous files


for cf in $FL
do
	echo $cf

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

# Merge files together
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

