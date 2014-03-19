#=========================================================================== 
#               Script for downloading  Data from Reverb 
#=========================================================================== 
  
import ftplib   #used for ftping into server 
import re       #used for string matching 
import time     #used for tracking time 
import os       #used for checking existance of files 
  
#=========================================================================== 
#               User Input values 
#=========================================================================== 
server = 'xfr140.larc.nasa.gov' #'n4ftl01u.ecs.nasa.gov'
directory= '/093c8e9c-0ee3-4cf7-b22b-723f3cb1aeb4' #'/DP0/MOST/MOD10A1.005'
#year = '2013'                                       
#match_parameters = '.*h11v12.*hdf(?!.xml)'
  
#=========================================================================== 
#               Code 
#=========================================================================== 
ftp=ftplib.FTP(server) 
ftp.login('anonymous','juicyfruit_2108@yahoo.com') 
  
ftp.cwd(directory) 
files=[] 

ftp.retrlines('LIST',files.append) 

for ceresfile in files:
    if not re.findall(r'\.met',ceresfile):
        fhandle = open(ceresfile,'wb')  
        ftp.retrbinary('RETR '+ceresfile,fhandle.write) 
        print('finished saving file') 
        fhandle.close()

#======================================================================
#                   MODIS
#=====================================================================
##print 'Greetings!'
##  
##for subDirinfo in files: 
##    subDir = subDirinfo.split(' ')[-1] 
##    if subDir[0:4] == year: 
##        ftp.cwd(subDir) 
##        allhdffiles = ftp.nlst() 
##        for hdf in allhdffiles: 
##            hdfmatch = re.match(match_parameters,hdf[:]) 
##            if not hdfmatch == None: 
##                fhandle = open(hdfmatch.group(0),'wb')  
##                ftp.retrbinary('RETR '+hdfmatch.group(0),fhandle.write) 
##                print('finished saving file') 
##                fhandle.close() 
##        ftp.cwd(directory) 
##          
##ftp.close() 
