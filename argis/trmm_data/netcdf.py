import os

targetDir = 'C:/Users/Owner/Documents/ArcGIS/netcdf/2012'
os.chdir(targetDir)
files = os.listdir(targetDir)
for f in files:
        fnew = f[16:18]+'_'+f[19:21]+'.nc'
        os.rename(f,fnew)
print "Finished renaming for file " + targetDir

