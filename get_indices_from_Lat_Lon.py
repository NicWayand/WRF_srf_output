import numpy as np
import netCDF4

# Simple script that takes lat lon pairs, and returns the nearest WRF grid indicies that are required for extraction

# Important!!! Required modules that must be loaded on the UW hyak system prior to running this script
# Netcdf package
#module load netcdf_4.3.2-icc_14.0.3
# Python package
#module load epd_7.3_2

#### EDIT HERE! ####

# Path of input file that lists lat lon pair of points
FILEIN   = '/civil/shared/snow/nicway/WRF/gridcell/SNQ'
# ex: -121.413914, 47.424955
#     -123.413914, 49.424955
# Path of output file that will contain WRF indices (is created is it doesn't exist)
FILEOUT  = '/civil/shared/snow/nicway/WRF/gridcell/SNQ_out_2.txt'
# Example file of WRF (any of the WRF files will do with same lat/lon extent)
filename = '/civil/shared/snow/nicway/WRF/wrfout_d4.2014040100.f12.0000'

####  DO WORK  ####

filelistin  = open(FILEIN,'r')
filelistout = open(FILEOUT,'w')

# Define naive_fast that searches for the nearest WRF grid cell center
def naive_fast(latvar,lonvar,lat0,lon0):
    # Read latitude and longitude from file into numpy arrays
    latvals = latvar[:]
    lonvals = lonvar[:]
    #print latvals, lonvals
    #iny,nx = latvals.shape
    dist_sq = (latvals-lat0)**2 + (lonvals-lon0)**2
    minindex_flattened = dist_sq.argmin()  # 1D index of min element
    iy_min,ix_min = np.unravel_index(minindex_flattened, latvals.shape)
    return str(iy_min),str(ix_min)

# Open example netcdf WRF file
ncfile = netCDF4.Dataset(filename, 'r')
latvar = ncfile.variables['XLAT'] # Get all Lat vars
lonvar = ncfile.variables['XLONG'] # Get all Lon vars
#newlat = latvar * np.ones((len(lonvar),len(latvar)))
#newlon = lonvar * np.ones((len(latvar),len(lonvar)))
newlat = np.squeeze(latvar) # Remove singlton dim (one time step)
newlon = np.squeeze(lonvar)

# For each input lat/lon pair, find nearest WRF grid and print out to FILEOUT
count = 1
for cl in filelistin:
	t_lon, t_lat = cl.split(',')
	print "Looking for lat lon pair..."
	print t_lat, t_lon
	#print t_lon, t_lat
	iy,ix = naive_fast(newlat,newlon, float(t_lat), float(t_lon))
	print "Found WRF lat lon and indicies"
	print newlat[iy,ix], newlon[iy,ix], iy, ix
	filelistout.write("%s %s %s %s %s %s %s\n" % (count, iy, ix, newlat[iy,ix], newlon[iy,ix], float(t_lat), float(t_lon)))
	count = count + 1	

filelistout.close()
filelistin.close()
#print 'Closest lat lon:', newlat[iy,ix], newlon[iy,ix]
#print 'index values for lat and lon are:', iy, ix
ncfile.close()

